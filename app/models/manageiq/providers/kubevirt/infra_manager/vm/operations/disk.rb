module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Disk
  def raw_attach_volume(vm, pvc_name, volume_name = nil)
    raise _("Unable to attach volume") unless ext_management_system
    kubevirt = ext_management_system.parent_manager.connect(
      :service => "kubernetes",
      :path    => "/apis/kubevirt.io",
      :version => "v1"
    )

    patch_ops = [
      {
        "op"    => "add",
        "path"  => "/spec/template/spec/volumes/-",
        "value" => {
          "name"                  => pvc_name || volume_name,
          "persistentVolumeClaim" => {
            "claimName" => pvc_name
          }
        }
      },
      {
        "op"    => "add",
        "path"  => "/spec/template/spec/domain/devices/disks/-",
        "value" => {
          "name" => pvc_name,
          "disk" => {
            "bus" => "virtio"
          }
        }
      }
    ]
    kubevirt.patch_entity(
      "virtualmachines",
      vm.name,
      patch_ops,
      "json-patch",
      vm.location
    )
  end

  def raw_detach_volume(vm, volume_name)
    raise _("Unable to detach volume") unless ext_management_system
    kubevirt = ext_management_system.parent_manager.connect(
      :service => "kubernetes",
      :path    => "/apis/kubevirt.io",
      :version => "v1"
    )
    vm_resource = kubevirt.get_entity("virtualmachines", vm.name, vm.location)
    volumes = vm_resource.spec.template.spec.volumes
    disks   = vm_resource.spec.template.spec.domain.devices.disks
    volume_index = volumes.index { |v| v.name == volume_name }
    disk_index   = disks.index { |d| d.name == volume_name }

    raise _("Volume not found") if volume_index.nil?
    raise _("Disk not found") if disk_index.nil?

    patch_ops = [
      {
        "op"   => "remove",
        "path" => "/spec/template/spec/volumes/#{volume_index}"
      },
      {
        "op"   => "remove",
        "path" => "/spec/template/spec/domain/devices/disks/#{disk_index}"
      }
    ]
    kubevirt.patch_entity(
      "virtualmachines",
      vm.name,
      patch_ops,
      "json-patch",
      vm.location
    )
  end

  def attached_volumes(vm)
    raise _("Unable to list attached volumes") unless ext_management_system
    kubevirt = ext_management_system.parent_manager.connect(
      :service => "kubernetes",
      :path    => "/apis/kubevirt.io",
      :version => "v1"
    )
    vm_resource = kubevirt.get_entity("virtualmachines", vm.name, vm.location)
    disks = vm_resource.spec.template.spec.domain.devices.disks
    disks.map(&:name).map do |v|
      {:metadata => {:name => v}}
    end
  end
  
  def persistentvolumeclaims(vm)
    raise _("Unable to list PVCs") unless ext_management_system
    kubevirt = ext_management_system.parent_manager.connect(
      :service => "kubernetes",
      :path    => "/apis/kubevirt.io",
      :version => "v1"
    )

    kube = ext_management_system.parent_manager.connect(
      :service => "kubernetes",
      :path    => "/api",
      :version => "v1"
    )

    namespace = vm.location
    pvcs = kube.get_persistent_volume_claims(:namespace => namespace)
    vms = kubevirt.get_virtual_machines(:namespace => namespace)
    attached_pvc_names = []
    vms.each do |vmi|
      vm_vols = vmi.spec.template.spec.volumes
      vm_vols.each do |vol|
        if vol.persistentVolumeClaim
          attached_pvc_names << vol.persistentVolumeClaim.claimName
        end
      end
    end
    attached_pvc_names.uniq!
    unattached_pvcs = pvcs.reject do |pvc|
      attached_pvc_names.include?(pvc.metadata.name)
    end
    unattached_pvcs.map do |pvc|
      {:metadata => {:name => pvc.metadata.name}}
    end
  end

  def create_pvc(vm, data)
    raise _("Unable to create PVC") unless ext_management_system
    kubevirt = ext_management_system.parent_manager.connect(
      :service => "kubernetes",
      :path    => "/api",
      :version => "v1"
    )
    namespace = vm.location
    pvc = {
      :apiVersion => "v1",
      :kind       => "PersistentVolumeClaim",
      :metadata   => {
        :name      => data['volume_name'],
        :namespace => namespace
      },
      :spec       => {
        :accessModes      => [data['access_mode'].presence || "ReadWriteOnce"],
        :resources        => {
          :requests => {
            :storage => data['volume_size']
          }
        },
        :storageClassName => data['storage_class']
      }
    }
    kubevirt.create_persistent_volume_claim(pvc)
    raw_attach_volume(vm, data['volume_name'])
  end

  def storage_classes
    raise _("Unable to list storage classes") unless ext_management_system
    storage_client = ext_management_system.parent_manager.connect(
      :service => "kubernetes",
      :path    => "/apis/storage.k8s.io",
      :version => "v1"
    )
    sc=storage_client.get_storage_classes
    sc.map { |s| { :name => s.metadata.name } }
  end
end
