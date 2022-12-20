#
# This class is responsible for parsing the inventory for partial refreshes.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser::PartialRefresh < ManageIQ::Providers::Kubevirt::Inventory::Parser
  def parse
    # Get the notices from the collector:
    nodes = collector.nodes
    vms = collector.vms
    vm_instances = collector.vm_instances
    templates = collector.templates

    # We need to find the identifiers of the objects *before* removing notices of type `DELETED`, because we need the
    # identifiers of all the objects, even of those that have been deleted.
    host_ids = get_object_ids(nodes)
    vm_ids = get_object_ids(vms)
    template_ids = get_object_ids(templates)

    # Build the list of identifiers for built-in objects:
    cluster_ids = [CLUSTER_ID]
    storage_ids = [STORAGE_ID]

    # In order to remove objects from the database we need to include the identifiers, but not the actual data, so we
    # must now discard all the notices of type `DELETED`.
    discard_deleted_notices(nodes)
    discard_deleted_notices(vms)
    discard_deleted_notices(vm_instances)
    discard_deleted_notices(templates)

    # Create the collections:
    @cluster_collection = persister.cluster_collection(:targeted => true, :ids => cluster_ids)
    @host_collection = persister.host_collection(:targeted => true, :ids => host_ids)
    @host_storage_collection = persister.host_storage_collection(:targeted => true)
    @hw_collection = persister.hw_collection(:targeted => true)
    @network_collection = persister.network_collection(:targeted => true)
    @os_collection = persister.os_collection(:targeted => true)
    @storage_collection = persister.storage_collection(:targeted => true, :ids => storage_ids)
    @template_collection = persister.template_collection(:targeted => true, :ids => template_ids)
    @vm_collection = persister.vm_collection(:targeted => true, :ids => vm_ids)
    @vm_os_collection = persister.vm_os_collection(:targeted => true, :ids => vm_ids)
    @disk_collection = persister.disk_collection(:targeted => true)

    # We need to add the built-in objects, otherwise other objects that reference them are removed:
    add_builtin_clusters
    add_builtin_storages

    # Process the real objects:
    process_nodes(nodes)
    process_vms(vms)
    process_vm_instances(vm_instances)
    process_templates(templates)
  end

  private

  def get_object_ids(notices)
    notices.map { |notice| notice.metadata.uid }.uniq
  end

  def discard_deleted_notices(notices)
    notices.reject! { |notice| notice.type == 'DELETED' }
  end
end
