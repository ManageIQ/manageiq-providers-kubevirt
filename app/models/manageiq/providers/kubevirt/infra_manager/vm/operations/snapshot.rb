module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Snapshot
  def raw_create_snapshot(snap_name, _desc = nil, _memory = false)
    kubevirt = ext_management_system.parent_manager.connect(:service => "kubernetes", :path => "/apis/snapshot.kubevirt.io", :version => "v1alpha1")
    kubevirt.create_virtual_machine_snapshot(
      :metadata => {
        :namespace => location,
        :name      => snap_name
      },
      :spec => {
        :source => {
          :apiGroup => "kubevirt.io",
          :kind     => "VirtualMachine",
          :name     => name
        }
      }
    )
  end
end

