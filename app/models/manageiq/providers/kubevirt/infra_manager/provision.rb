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

class ManageIQ::Providers::Kubevirt::InfraManager::Provision < MiqProvision
  include_concern 'Cloning'
  include_concern 'StateMachine'

  #
  # The ManageIQ core calls this method during the provision workflow to get the name of the object that is being
  # provisioned, only to include it in the generated log messages.
  #
  def destination_type
    'VM'
  end
end
