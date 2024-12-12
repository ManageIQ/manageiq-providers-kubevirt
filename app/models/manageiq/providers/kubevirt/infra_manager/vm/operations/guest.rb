module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Guest

  def raw_reboot_guest
    kubevirt = ext_management_system.parent_manager.connect(:service => "kubernetes", :path => "/apis/subresources.kubevirt.io", :version => "v1")
    #method need to call on this kubevirt to restart the vm

  end

  def raw_reset
    kubevirt = ext_management_system.parent_manager.connect(:service => "kubernetes", :path => "/apis/subresources.kubevirt.io", :version => "v1")
    #method need to call on this kubevirt to soft reboot the vm

  end
end