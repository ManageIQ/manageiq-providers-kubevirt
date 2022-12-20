module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Power
  def raw_start
    ext_management_system.with_provider_connection do |connection|
      # Retrieve the details of the virtual machine:
      vm = connection.vm(name)
      vm.start
    end
  end

  def raw_stop
    ext_management_system.with_provider_connection do |connection|
      # Retrieve the details of the virtual machine:
      vm = connection.vm(name)
      vm.stop
    end
  end
end
