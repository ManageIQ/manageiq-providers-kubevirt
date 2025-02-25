require 'json'
require 'yaml'

module ManageIQ::Providers::Kubevirt::InfraManager::Provision::Cloning
  def find_destination_in_vmdb(ems_ref)
    ::Vm.find_by(:ems_id => source.ext_management_system.id, :ems_ref => ems_ref)
  end

  def prepare_for_clone_task
    raise MiqException::MiqProvisionError, "Provision request's destination virtual machine cannot be blank" if dest_name.blank?
    raise MiqException::MiqProvisionError, "A virtual machine with name '#{dest_name}' already exists" if source.ext_management_system.vms.where(:name => dest_name).any?

    {
      :name => dest_name,
    }
  end

  def log_clone_options(clone_options)
    _log.info("Provisioning '#{source.name}' to '#{dest_name}'")
    _log.info("Source template name is '#{source.name}'")
    _log.info("Destination virtual machine name is '#{clone_options[:name]}'")

    dump_obj(clone_options, "#{_log.prefix} Clone options: ", $log, :info)
    dump_obj(options, "#{_log.prefix} Provision options: ", $log, :info, :protected => {:path => workflow_class.encrypted_options_field_regs})
  end

  def start_clone(options)
    source.with_provider_connection do |connection|
      # Retrieve the details of the source template:
      template    = source.provider_object
      namespace ||= source.location

      vm_params = values(template, user_options(options))
      pvc_specs = template.objects.select { |o| o[:kind] == "PersistentVolumeClaim" }
      # TODO create pvcs
      vm_spec   = template.objects.detect { |o| o[:kind] == "VirtualMachine" }&.to_h
      raise N_("No Virtual Machine defined in template") if vm_spec.nil?

      param_substitution!(vm_spec, vm_params)
      vm_spec.deep_merge!(:spec => {:running => false}, :metadata => {:namespace => namespace})

      begin
        vm, _, _ = connection.create_namespaced_virtual_machine(namespace, vm_spec)
      rescue
        # TODO: check if we need to roll back if one object creation fails
      end

      phase_context[:new_vm_ems_ref] = vm.metadata.uid
    end

  end

  private

  #
  # Merges user given options with user options that are specified on the request.
  # The returned Hash will contain keys as expected by the kubevirt template.
  #
  # @param options [Hash] the given options by the user
  # @return [Hash] Hash that contains additional user options as specified on the request
  #
  def user_options(options)
    merged_options = options.dup
    merged_options[:cpu_cores] = get_option(:cores_per_socket)
    merged_options[:memory] = get_option(:vm_memory)
    merged_options[:cloud_user_password] = ManageIQ::Password.try_decrypt(get_option(:root_password))
    merged_options.compact
  end

  def values(template, options)
    default_params = {}
    template.parameters.each do |param|
      name = param[:name].downcase
      value = options[name.to_sym]
      if value && name == "memory"
        value = "#{value}Mi"
      end

      default_params[name] = value || param[:value]
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
      result = sub_specific_object(params, object)
    end
    result
  end

  #
  # Performs substitution on specific object.
  #
  # @params params [Hash] Containing parameter names and values used for substitution.
  # @params object [String] Object on which substitution takes place.
  # @returns [String] The outcome of substitution.
  #
  def sub_specific_object(params, object)
    result = object
    params.each_key do |name|
      token = "${#{name.upcase}}"
      os_token = "${{#{name.upcase}}}"
      next unless object.include?(token) || object.include?(os_token)

      result = if params[name].kind_of?(String)
                 if object.include?(os_token)
                   object.sub!(os_token, params[name])
                 else
                   object.sub!(token, params[name])
                 end
               else
                 params[name]
               end
    end
    result
  end
end
