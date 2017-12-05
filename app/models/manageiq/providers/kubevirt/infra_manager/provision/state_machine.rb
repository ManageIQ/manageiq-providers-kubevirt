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

module ManageIQ::Providers::Kubevirt::InfraManager::Provision::StateMachine
  def create_destination
    signal :determine_placement
  end

  def determine_placement
    signal :prepare_provision
  end

  def start_clone_task
    update_and_notify_parent(:message => "Starting clone of #{clone_direction}")

    log_clone_options(phase_context[:clone_options])
    start_clone(phase_context[:clone_options])
    phase_context.delete(:clone_options)

    signal :poll_destination_in_vmdb
  end

  def customize_destination
    signal :post_provision
  end
end
