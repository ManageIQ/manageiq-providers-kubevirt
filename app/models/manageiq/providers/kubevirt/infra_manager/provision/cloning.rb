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
      template.clone(user_options(options))

      vm = connection.vm(options[:name])

      phase_context[:new_vm_ems_ref] = vm.uid
    end

    # TODO: check if we need to roll back if one object creation fails
  end

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
    merged_options.compact
  end
end
