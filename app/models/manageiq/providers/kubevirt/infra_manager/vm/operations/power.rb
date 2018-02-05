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

module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Power
  def raw_start
    ext_management_system.with_provider_connection do |connection|
      # Retrieve the details of the offline virtual machine:
      offline_vm = connection.offline_vm(name)

      # Change the `running` attribute to `true` so that the offline virtual machine controller will take it and create
      # the live virtual machine.
      offline_vm.spec.running = true
      connection.update_offline_vm(offline_vm)

      # TODO: We need to create the live virtual machine explicitly because KubeVirt still doesn't have a controller
      # that starts automatically the virtual machines when the `running` attribute is changed to `true`. This should be
      # removed when that controller is added.
      live_vm = {
        :metadata => {
          :namespace       => offline_vm.metadata.namespace,
          :name            => name,
          :ownerReferences => [{
            :apiVersion => offline_vm.apiVersion,
            :kind       => offline_vm.kind,
            :name       => offline_vm.metadata.name,
            :uid        => offline_vm.metadata.uid
          }]
        },
        :spec     => offline_vm.spec.template.spec.to_h
      }

      # make sure to copy vm presets
      unless offline_vm.metadata.selector.nil?
        live_vm.deep_merge!(
          :metadata => {
            :namespace => {
              :selector => offline_vm.metadata.selector
            }
          }
        )
      end

      connection.create_live_vm(live_vm)
    end
  end

  def raw_stop
    ext_management_system.with_provider_connection do |connection|
      # Retrieve the details of the offline virtual machine:
      offline_vm = connection.offline_vm(name)

      # Change the `running` attribute to `false` so that the offline virtual machine controller will take it and delete
      # the live virtual machine.
      offline_vm.spec.running = false
      connection.update_offline_vm(offline_vm)

      # TODO: We need to delete the virtual machine explicitly because KubeVirt still doesn't have a controller that
      # stops automatically the virtual machines when the `running` attribute is changed to `false`. This should be
      # removed when that controller is added.
      connection.delete_live_vm(name, offline_vm.metadata.namespace)
    end
  end
end
