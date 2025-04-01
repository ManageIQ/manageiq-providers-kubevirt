#
# This class is responsible for parsing the inventory for full refreshes.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser::InfraManager < ManageIQ::Providers::Kubevirt::Inventory::Parser
  def parse
    # Add the built-in objects:
    add_builtin_clusters
    add_builtin_storages

    # Process the real objects:
    process_nodes(collector.nodes)
    process_vms(collector.vms)
    process_vm_instances(collector.vm_instances)
    process_templates(collector.templates)
  end
end
