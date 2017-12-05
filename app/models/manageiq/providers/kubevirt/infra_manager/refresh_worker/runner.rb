#
# Copyright (c) 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'thread'
require 'concurrent/atomic/atomic_boolean'

class ManageIQ::Providers::Kubevirt::InfraManager::RefreshWorker::Runner < ManageIQ::Providers::BaseManager::RefreshWorker::Runner
  def do_before_work_loop
    super

    # Find the manager:
    @manager = ManageIQ::Providers::Kubevirt::InfraManager.find(@cfg[:ems_id])

    # We will put in this queue the notices received from the watchers, and also the artificial
    # notices that we generate ourselves for full refreshes:
    @notices = Queue.new

    # This flag will be used to tell the threads to get out of their loops:
    @finish = Concurrent::AtomicBoolean.new(false)

    # Create the watches:
    opts = {
      'resourceVersion' => 0
    }
    @watches = []
    @manager.with_provider_connection do |connection|
      #@watches << connection.watch_nodes(opts)
      @watches << connection.watch_stored_virtual_machines(opts)
      @watches << connection.watch_virtual_machine_templates(opts)
      @watches << connection.watch_virtual_machines(opts)
    end

    # Create the threads that run the watches and put the notices in the queue:
    @watchers = []
    @watches.each do |watch|
      thread = Thread.new do
        until @finish.value
          watch.each do |notice|
            @notices.push(notice)
          end
        end
      end
      @watchers << thread
    end

    # Create the thread that processes the notices from the queue and persists the results. It will
    # exit when it detects a `nil` in the queue.
    @processor = Thread.new do
      loop do
        notice = @notices.pop
        break unless notice
        process_notice(notice)
      end
    end
  end

  def before_exit(message, _exit_code)
    super

    # Ask the watch threads to finish, and wait for them:
    @finish.value = true
    @watches.each(&:finish)
    @watchers.each(&:join)

    # Ask the processor thread to finish, and wait for it:
    @notices.push(nil)
    @processor.join
  end

  private

  def process_notice(notice)
    # Determine the set of targets that are affected by this notice:
    targets = [@manager]

    # Create a new instance of the provider refresher and use it to perform the refresh:
    refresher_class = @manager.refresher
    refresher = refresher_class.new(targets)
    refresher.refresh
  end
end
