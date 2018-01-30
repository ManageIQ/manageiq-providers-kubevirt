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
require 'json'
require 'yaml'

module ManageIQ::Providers::Kubevirt::InfraManager::Provision::Cloning
  def find_destination_in_vmdb(ems_ref)
    ::Vm.find_by(:ems_id => source.ext_management_system.id, :ems_ref => ems_ref)
  end

  def prepare_for_clone_task
    raise MiqException::MiqProvisionError, "Provision request's destination virtual machine cannot be blank" if dest_name.blank?
    raise MiqException::MiqProvisionError, "A virtual machine with name '#{dest_name}' already exists" if source.ext_management_system.vms.where(:name => dest_name).any?

    clone_options = {
      :name => dest_name,
    }
    clone_options
  end

  def log_clone_options(clone_options)
    _log.info("Provisioning '#{source.name}' to '#{dest_name}'")
    _log.info("Source template name is '#{source.name}'")
    _log.info("Destination virtual machine name is '#{clone_options[:name]}'")

    dump_obj(clone_options, "#{_log.prefix} Clone options: ", $log, :info)
    dump_obj(options, "#{_log.prefix} Provision options: ", $log, :info, :protected => {:path => workflow_class.encrypted_options_field_regs})
  end

  def start_clone(options)
    # Retrieve the details of the source template:
    template = nil
    source.with_provider_connection do |connection|
      template = connection.template(source.name)
    end

    # Load example file due to current limitations of kubevirt
    # TODO: remove when kubevirt provides the implementation
    example = example_template
    params = values(example, options)

    # use persistent volume claims if any from a template and send
    create_persistent_volume_claims(persistent_volume_claims_from_objects(example.objects), params, template.metadata.namespace)

    # use offline vm definition from a template and send
    create_offline_vm(offline_vm_from_objects(example.objects), params, phase_context, template.metadata.namespace)

    # TODO: check if we need to roll back if one object creation fails
  end

  def create_offline_vm(offline_vm, params, phase_context, namespace)
    offline_vm = param_substitution!(offline_vm, params)

    offline_vm.deep_merge!(
      :metadata => {
        :namespace => namespace
      }
    )

    # Send the request to create the offline virtual machine:
    source.with_provider_connection do |connection|
      offline_vm = connection.create_offline_vm(offline_vm)
    end

    # Save the identifier of the new virtual machine to the request context, so that it can later
    # be used to check if it has been already created:
    phase_context[:new_vm_ems_ref] = offline_vm.metadata.uid
  end

  def create_persistent_volume_claims(pvcs, params, namespace)
    pvcs.each do |pvc|
      pvc = param_substitution!(pvc, params)

      pvc.deep_merge!(
        :metadata => {
          :namespace => namespace
        }
      )

      # Send the request to create the persistent volume claim:
      source.with_provider_connection do |connection|
        connection.create_pvc(pvc)
      end
    end
  end

  private

  def offline_vm_from_objects(objects)
    vm = nil
    objects.each do |object|
      if object.kind == "OfflineVirtualMachine"
        vm = to_hash(object)
      end
    end
    # make sure there is one
    raise MiqException::MiqProvisionError if vm.nil?
    vm
  end

  def persistent_volume_claims_from_objects(objects)
    pvcs = []
    objects.each do |object|
      if object.kind == "PersistentVolumeClaim"
        pvcs << to_hash(object)
      end
    end
    pvcs
  end

  def values(template, options)
    default_params = {}
    template.parameters.each do |param|
      name = param.name.downcase
      value = options[name.to_sym]
      if value && name == "memory"
        value = value.to_s + 'Mi'
      end

      default_params[name] = value || param.value
    end
    default_params
  end

  def param_substitution!(object, params)
    result = object
    case result
    when Hash
      result.each do |k, v|
        result[k] = param_substitution!(v, params)
      end
    when Array
      result.map { |v| param_substitution!(v, params) }
    when String
      result = substitute_param(params, object)
    end
    result
  end

  def substitute_param(params, object)
    result = object
    params.each_key do |name|
      token = "${#{name.upcase}}"
      next unless object.include?(token)
      result = if params[name].kind_of?(String)
                 object.sub!(token, params[name])
               else
                 params[name]
               end
    end
    result
  end

  def to_hash(object)
    result = object
    case result
    when OpenStruct
      result = result.marshal_dump
      result.each do |k, v|
        result[k] = to_hash(v)
      end
    when Array
      result = result.map { |v| to_hash(v) }
    end
    result
  end

  # This method is a workaround for now till we have a way to get a template
  def example_template
    filepath = __dir__
    top = filepath.split(File::SEPARATOR)[1..-8]
    path = top.push('manifests').push('example-template.yml')
    example = YAML.load_file(File::SEPARATOR + path.join(File::SEPARATOR))
    JSON.parse(example.to_json, :object_class => OpenStruct)
  end
end
