module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Reconfigure
  extend ActiveSupport::Concern

  def reconfigurable?
    active?
  end

  def max_vcpus
    ext_management_system.host_hardwares.pluck(:cpu_total_cores).max
  end
  alias max_total_vcpus max_vcpus
  alias max_cpu_cores_per_socket max_vcpus

  def max_memory_mb
    ext_management_system.host_hardwares.pluck(:memory_mb).max
  end

  def validate_config_spec(options)
    if flavor
      if %i[number_of_sockets cores_per_socket vm_memory].any? { |key| options.key?(key) }
        raise MiqException::MiqVmError, _("Setting CPUs / Memory not supported for instance_type VMs")
      end
    else
      if options.key?(:flavor_id)
        raise MiqException::MiqVmError, _("Setting instance_type not supported for template VMs")
      end
    end
  end

  def build_config_spec(options)
    validate_config_spec(options)

    patches = []
    if options[:flavor_id]
      flavor = ext_management_system.flavors.find(options[:flavor_id])
      patches << {"op" => "replace", "path" => "/spec/instancetype", "value" => {"kind" => "VirtualMachineClusterInstancetype", "name" => flavor.name}}
    else
      patches << {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/sockets",  "value" => options[:number_of_sockets]} if options[:number_of_sockets]
      patches << {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/cores",    "value" => options[:cores_per_socket]}  if options[:cores_per_socket]
      patches << {"op" => "replace", "path" => "/spec/template/spec/domain/memory/guest", "value" => "#{options[:vm_memory]}Mi"}  if options[:vm_memory]
    end
    patches
  end
end
