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

require 'concurrent/atomic/atomic_boolean'
require 'kubeclient'
require 'thread'

class ManageIQ::Providers::Kubevirt::InfraManager::RefreshWorker::Runner < ManageIQ::Providers::BaseManager::RefreshWorker::Runner
  def do_before_work_loop
    # Load the refresh memory. If it is empty then we need to perform a full refresh, and initialize it.
    if memory.empty?
      full_refresh
      initialize_memory
    end

    # We will put in this queue the notices received from the watchers:
    @queue = Queue.new

    # This flag will be used to tell the threads to get out of their loops:
    @finish = Concurrent::AtomicBoolean.new(false)

    # Create the thread that processes the notices from the queue and persists the results. It will
    # exit when it detects a `nil` in the queue.
    @processor = Thread.new do
      loop do
        # We want to process noticies in blocks, which will be stored in this array:
        notices = []

        # Wait till there is at least one notice in the queue:
        notice = @queue.pop
        notices.push(notice)

        # Fetch as many notices as are already available in the queue:
        until @queue.empty?
          notice = @queue.pop
          notices.push(notice)
        end

        # Check if the last notice in the block is `nil`, as that is the signal to stop:
        stop = notices.last.nil?

        # Remove the last `nil` notice, and process the rest of the block:
        notices.delete_at(notices.length - 1) if stop
        partial_refresh(notices)

        # Stop if signaled to do so:
        break if stop
      end
    end

    # Create the watches:
    @watches = []
    manager.with_provider_connection do |connection|
      @watches << connection.watch_nodes('resourceVersion' => memory.get_list_version(:nodes))
      @watches << connection.watch_stored_virtual_machines('resourceVersion' => memory.get_list_version(:stored_vms))
      @watches << connection.watch_virtual_machines('resourceVersion' => memory.get_list_version(:live_vms))
      @watches << connection.watch_virtual_machine_templates('resourceVersion' => memory.get_list_version(:templates))
    end

    # Create the threads that run the watches and put the notices in the queue:
    @watchers = []
    @watches.each do |watch|
      thread = Thread.new do
        until @finish.value
          watch.each do |notice|
            @queue.push(notice)
          end
        end
      end
      @watchers << thread
    end
  end

  def before_exit(message, _exit_code)
    # Ask the watch threads to finish, and wait for them:
    @finish.value = true
    @watches.each(&:finish)
    @watchers.each(&:join)

    # Ask the processor thread to finish, and wait for it:
    @queue.push(nil)
    @processor.join
  end

  private

  #
  # Returns the reference to the manager.
  #
  # @return [ManageIQ::Providers::Kubevirt::InfraManager] The manager.
  #
  def manager
    @manager ||= ManageIQ::Providers::Kubevirt::InfraManager.find(@cfg[:ems_id])
  end

  #
  # Returns the refresh memory.
  #
  # @return [ManageIQ::Providers::Kubevirt::RefreshMemory] The refresh memory.
  #
  def memory
    @memory ||= ManageIQ::Providers::Kubevirt::RefreshMemory.new(manager.id)
  end

  #
  # Initializes the memory, setting the last version to zero for all the watched collections.
  #
  def initialize_memory
    memory.add_list_version(:nodes, collector.nodes.resourceVersion)
    memory.add_list_version(:stored_vms, collector.stored_vms.resourceVersion)
    memory.add_list_version(:live_vms, collector.live_vms.resourceVersion)
    memory.add_list_version(:templates, collector.templates.resourceVersion)
  end

  #
  # Performs a full refresh.
  #
  def full_refresh
    # Create and populate the collector:
    collector = ManageIQ::Providers::Kubevirt::Inventory::Collector.new(manager, manager)
    manager.with_provider_connection do |connection|
      collector.nodes = connection.nodes
      collector.stored_vms = connection.stored_virtual_machines
      collector.live_vms = connection.virtual_machines
      collector.templates = connection.virtual_machine_templates
    end

    # Create the parser and persister, wire them, and execute the persist:
    persister = ManageIQ::Providers::Kubevirt::Inventory::Persister.new(manager, manager)
    parser = ManageIQ::Providers::Kubevirt::Inventory::Parser::FullRefresh.new
    parser.collector = collector
    parser.persister = persister
    parser.parse
    persister.persist!

    # Update the memory:
    memory.add_list_version(:nodes, collector.nodes.resourceVersion)
    memory.add_list_version(:stored_vms, collector.stored_vms.resourceVersion)
    memory.add_list_version(:live_vms, collector.live_vms.resourceVersion)
    memory.add_list_version(:templates, collector.templates.resourceVersion)
  rescue => error
    _log.error('Full refresh failed.')
    _log.log_backtrace(error)
  end

  #
  # Performs a partial refresh.
  #
  # @param notices [Array] The set of notices to process.
  #
  def partial_refresh(notices)
    # Filter out the notices that have already been processed:
    notices.reject! do |notice|
      object = notice.object
      metadata = object.metadata
      if memory.contains_notice?(notice)
        _log.info(
          "Notice of kind '#{object.kind}, id '#{metadata.uid}', type '#{notice.type}' and version '#{metadata.resourceVersion}' " \
          "has already been processed, will ignore it."
        )
        true
      else
        false
      end
    end

    # The notices returned by the Kubernetes API contain always the complete representation of the object, so it isn't
    # necessary to process all of them, only the last one for each object.
    relevant = notices.reverse!
    relevant.uniq! { |notice| notice.object.uid }
    relevant.reverse!

    # Create and populate the collector:
    collector = ManageIQ::Providers::Kubevirt::Inventory::Collector.new(manager, nil)
    collector.nodes = notices_of_kind(relevant, 'Node')
    collector.stored_vms = notices_of_kind(relevant, 'StoredVirtualMachine')
    collector.live_vms = notices_of_kind(relevant, 'VirtualMachine')
    collector.templates = notices_of_kind(relevant, 'VirtualMachineTemplate')

    # Create the parser and persister, wire them, and execute the persist:
    persister = ManageIQ::Providers::Kubevirt::Inventory::Persister.new(manager, nil)
    parser = ManageIQ::Providers::Kubevirt::Inventory::Parser::PartialRefresh.new
    parser.collector = collector
    parser.persister = persister
    parser.parse
    persister.persist!

    # Update the memory:
    notices.each do |notice|
      memory.add_notice(notice)
    end
  rescue => error
    _log.error('Partial refresh failed.')
    _log.log_backtrace(error)
  end

  #
  # Returns the notices that contain objects of the given kind.
  #
  # @param notices [Array] An array of notices.
  # @param kind [String] The kind of object, for example `Node`.
  # @return [Array] An array containing the notices that have the given kind.
  #
  def notices_of_kind(notices, kind)
    notices.select { |notice| notice.object.kind == kind }
  end
end
