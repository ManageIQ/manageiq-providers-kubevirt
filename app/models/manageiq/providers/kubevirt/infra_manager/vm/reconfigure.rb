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

  def build_config_spec(options)
    patches = []
    patches << {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/sockets",  "value" => options[:number_of_sockets]} if options[:number_of_sockets]
    patches << {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/cores",    "value" => options[:cores_per_socket]}  if options[:cores_per_socket]
    patches << {"op" => "replace", "path" => "/spec/template/spec/domain/memory/guest", "value" => "#{options[:vm_memory]}Mi"}  if options[:vm_memory]
    patches
  end
end
