module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Reconfigure
  extend ActiveSupport::Concern

  def reconfigurable?
    active?
  end

  def max_vcpus
    host ? host.hardware.cpu_total_cores : raise # TOOD
  end
  alias max_total_vcpus max_vcpus

  def max_cpu_cores_per_socket(_total_vcpus = nil)
    max_vcpus
  end

  def max_memory_mb
    host.hardware.memory_mb
  end

  def build_config_spec(options)
    patches = []
    patches << {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/sockets",  "value" => options[:number_of_sockets]} if options[:number_of_sockets]
    patches << {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/cores",    "value" => options[:cores_per_socket]}  if options[:cores_per_socket]
    patches << {"op" => "replace", "path" => "/spec/template/spec/domain/memory/guest", "value" => "#{options[:vm_memory]}Mi"}  if options[:vm_memory]
    patches
  end
end
