#
# This class is responsible for persisting the inventory for a partial refresh.
#
class ManageIQ::Providers::Kubevirt::Inventory::Persister < ManageIQ::Providers::Inventory::Persister
  def cluster_collection(targeted: false, ids: [])
    add_collection(infra, :clusters) do |builder|
      builder.add_properties(
        :manager_uuids => ids,
        :targeted      => targeted
      )
    end
  end

  def host_collection(targeted: false, ids: [])
    add_collection(infra, :hosts) do |builder|
      builder.add_properties(
        :manager_uuids => ids,
        :targeted      => targeted
      )
    end
  end

  def host_storage_collection(targeted: false)
    add_collection(infra, :host_storages) do |builder|
      builder.add_properties(
        :targeted                     => targeted,
        :parent_inventory_collections => %i(hosts)
      )
      builder.add_targeted_arel(lambda do |collection|
                                  host_ids = collection.parent_inventory_collections.flat_map { |c| c.manager_uuids.to_a }
                                  collection.parent.host_storages.references(:host).where(
                                    :hosts => { :ems_ref => host_ids }
                                  )
                                end)
    end
  end

  def hw_collection(targeted: false)
    add_collection(infra, :hardwares) do |builder|
      builder.add_properties(
        :targeted => targeted
      )
    end
  end

  def network_collection(targeted: false)
    add_collection(infra, :networks) do |builder|
      builder.add_properties(
        :targeted                     => targeted,
        :manager_ref                  => %i(hardware ipaddress),
        :parent_inventory_collections => %i(vms)
      )
    end
  end

  def os_collection(targeted: false)
    add_collection(infra, :host_operating_systems) do |builder|
      builder.add_properties(
        :targeted                     => targeted,
        :parent_inventory_collections => %i(hosts)
      )
    end
  end

  def template_collection(targeted: false, ids: [])
    add_collection(infra, :miq_templates) do |builder|
      builder.add_properties(
        :targeted                     => targeted,
        :manager_uuids                => ids,
        :parent_inventory_collections => %i(vms)
      )
    end
  end

  def storage_collection(targeted: false, ids: [])
    add_collection(infra, :storages) do |builder|
      builder.add_properties(
        :targeted      => targeted,
        :manager_uuids => ids,
      )
    end
  end

  def vm_collection(targeted: false, ids: [])
    add_collection(infra, :vms) do |builder|
      builder.add_properties(
        :targeted      => targeted,
        :manager_uuids => ids,
      )
    end
  end

  def vm_os_collection(targeted: false, ids: [])
    add_collection(infra, :operating_systems) do |builder|
      builder.add_properties(
        :targeted                     => targeted,
        :manager_uuids                => ids,
        :manager_ref                  => %i(vm_or_template),
        :parent_inventory_collections => %i(vms)
      )
    end
  end

  def disk_collection(targeted: false)
    add_collection(infra, :disks) do |builder|
      builder.add_properties(
        :targeted => targeted,
      )
    end
  end

  protected

  def strategy
    :local_db_find_missing_references
  end
end
