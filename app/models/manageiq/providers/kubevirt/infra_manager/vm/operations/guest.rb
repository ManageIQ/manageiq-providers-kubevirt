module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Guest

  def raw_reboot_guest
    kubevirt = ext_management_system.parent_manager.connect(:service => "kubernetes", :path => "/apis/subresources.kubevirt.io", :version => "v1")
    kubevirt.rest_client["namespaces/#{location}/virtualmachineinstances/#{name}/softreboot"].put({}.to_json, { 'Content-Type' => 'application/json' }.merge(kubevirt.get_headers))
  end

  def raw_reset
    kubevirt = ext_management_system.parent_manager.connect(:service => "kubernetes", :path => "/apis/subresources.kubevirt.io", :version => "v1")
    kubevirt.rest_client["namespaces/#{location}/virtualmachines/#{name}/restart"].put({}.to_json, { 'Content-Type' => 'application/json' }.merge(kubevirt.get_headers))
  end
end