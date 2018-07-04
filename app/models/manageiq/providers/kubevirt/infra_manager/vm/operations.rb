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
require 'fog/kubevirt'

module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations
  extend ActiveSupport::Concern

  include_concern 'Power'

  def raw_destroy
    ext_management_system.with_provider_connection do |connection|
      # Retrieve the details of the virtual machine:
      begin
        vm_instance = connection.vm_instance(name)
      rescue Fog::Kubevirt::Errors::ClientError
        # the virtual machine instance doesn't exist
        vm_instance = nil
      end

      # delete vm instance
      connection.delete_vm_instance(name) unless vm_instance.nil?
    end
  end
end
