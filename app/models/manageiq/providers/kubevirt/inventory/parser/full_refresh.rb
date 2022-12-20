#
# This class is responsible for parsing the inventory for full refreshes.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser::FullRefresh < ManageIQ::Providers::Kubevirt::Inventory::Parser
  def parse
    # Get the objects from the collector:
    nodes = collector.nodes
    vms = collector.vms
    vm_instances = collector.vm_instances
    templates = collector.templates

    # Create the collections:
    @cluster_collection = persister.cluster_collection
    @host_collection = persister.host_collection
    @host_storage_collection = persister.host_storage_collection
    @hw_collection = persister.hw_collection
    @network_collection = persister.network_collection
    @os_collection = persister.os_collection
    @storage_collection = persister.storage_collection
    @template_collection = persister.template_collection
    @vm_collection = persister.vm_collection
    @vm_os_collection = persister.vm_os_collection
    @disk_collection = persister.disk_collection

    # Add the built-in objects:
    add_builtin_clusters
    add_builtin_storages

    # Process the real objects:
    process_nodes(nodes)
    process_vms(vms)
    process_vm_instances(vm_instances)
    process_templates(templates)
  end
end
