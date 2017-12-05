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

module ManageIQ::Providers::Kubevirt::InfraManager::Provision::Cloning
  def find_destination_in_vmdb(ems_ref)
    ::Vm.find_by(ems_id: source.ext_management_system.id,  ems_ref: ems_ref)
  end

  def prepare_for_clone_task
    raise MiqException::MiqProvisionError, "Provision request's destination VM Name=[#{dest_name}] cannot be blank" if dest_name.blank?
    raise MiqException::MiqProvisionError, "A virtual machine with name '#{dest_name}' already exists" if source.ext_management_system.vms.where(:name => dest_name).any?

    clone_options = {
      name: dest_name,
    }
    clone_options
  end

  def log_clone_options(clone_options)
    _log.info("Provisioning [#{source.name}] to [#{dest_name}]")
    _log.info("Source Template: [#{source.name}]")
    _log.info("Destination VM Name: [#{clone_options[:name]}]")

    dump_obj(clone_options, "#{_log.prefix} Clone Options: ", $log, :info)
    dump_obj(options, "#{_log.prefix} Prov Options: ", $log, :info, :protected => {:path => workflow_class.encrypted_options_field_regs})
  end

  def start_clone(options)
    # Get the name of the new virtual machine:
    name = options[:name]

    # Retrieve the details of the source template:
    virtual_machine_template = nil
    source.with_provider_connection do |connection|
      virtual_machine_template = connection.virtual_machine_template(source.name)
    end

    # Create the representation of the new stored virtual machine, copying the spec from the template:
    stored_virtual_machine = {
      metadata: {
        name: name,
        namespace: virtual_machine_template.metadata.namespace
      },
      spec: virtual_machine_template.spec.to_h
    }

    # If the memory has been explicitly specified in the options, then replace the value defined by the template:
    memory = get_option(:vm_memory)
    if memory
      stored_virtual_machine.deep_merge!(
        spec: {
          domain: {
            memory: {
              value: memory.to_i,
              unit: 'MiB'
            }
          }
        }
      )
    end

    # Send the request to create the stored virtual machine:
    source.with_provider_connection do |connection|
      stored_virtual_machine = connection.create_stored_virtual_machine(stored_virtual_machine)
    end

    # Save the identifier of the new virtual machine to the request context, so that it can later
    # be used to check if it has been already created:
    phase_context[:new_vm_ems_ref] = stored_virtual_machine.metadata.uid
  end
end
