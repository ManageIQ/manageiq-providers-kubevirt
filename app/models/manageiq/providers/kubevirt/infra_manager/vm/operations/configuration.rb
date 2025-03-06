module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Configuration
  extend ActiveSupport::Concern

  def raw_set_number_of_cpus(num)
    raw_reconfigure(
      [
        {
          "op"    => "replace",
          "path"  => "/spec/template/spec/domain/cpu/sockets",
          "value" => num
        }
      ]
    )
  end

  def raw_set_memory(memory_mb)
    raw_reconfigure(
      [
        {
          "op"    => "replace",
          "path"  => "/spec/template/spec/domain/memory/guest",
          "value" => "#{memory_mb}Mi"
        }
      ]
    )
  end

  def raw_reconfigure(options)
    with_provider_connection do |connection|
      connection.patch_namespaced_virtual_machine(name, location, options)
    end
  end
end
