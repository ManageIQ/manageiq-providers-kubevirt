module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Guest

  def raw_reboot_guest
    with_provider_connection do |connection|
      connection.v1_soft_reboot(name, location)
    end
  end

  def raw_reset
    with_provider_connection do |connection|
      connection.v1_restart(name, location)
    end
  end
end
