#
# This class is responsible for parsing the inventory for partial refreshes.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser::PartialTargetRefresh < ManageIQ::Providers::Kubevirt::Inventory::Parser
  def parse
    # Get the objects from the collector:
    nodes = collector.nodes || []
    vms = collector.vms || []
    vm_instances = collector.vm_instances || []
    templates = collector.templates || []

    vm_ids = get_object_ids(vms)
    template_ids = get_object_ids(templates)
    host_ids = get_object_ids(nodes)

    # Build the list of identifiers for built-in objects:
    cluster_ids = [CLUSTER_ID]
    storage_ids = [STORAGE_ID]

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
    @vm_os_collection = persister.vm_os_collection(:targeted => true)
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

  def get_object_ids(objects)
    objects.map { |o| o.uid }.uniq
  end
end
