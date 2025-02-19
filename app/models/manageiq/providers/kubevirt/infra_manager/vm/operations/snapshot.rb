module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Snapshot
  def raw_create_snapshot(snap_name, _desc = nil, _memory = false)
    with_provider_connection do |connection|
      snapshot_spec = Kubevirt::V1beta1VirtualMachineSnapshot.new(
        :api_version => "snapshot.kubevirt.io/v1beta1",
        :kind        => "VirtualMachineSnapshot",
        :metadata    => Kubevirt::K8sIoApimachineryPkgApisMetaV1ObjectMeta.new(
          :name      => snap_name,
          :namespace => location
        ),
        :spec        => Kubevirt::V1beta1VirtualMachineSnapshotSpec.new(
          :source => Kubevirt::K8sIoApiCoreV1TypedLocalObjectReference.new(
            :api_group => "kubevirt.io",
            :kind      => "VirtualMachine",
            :name      => name
          )
        )
      )

      connection.create_namespaced_virtual_machine_snapshot(location, snapshot_spec)
    end
  end
end

