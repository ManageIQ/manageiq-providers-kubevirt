#
# This class contains the data needed to perform a refresh. The data are the collections of nodes, virtual machines and
# templates retrieved using the KubeVirt API.
#
# Note that unlike other typical collectors it doesn't really retrieve that data itself: the refresh worker will create
# with the data that it already obtained from the KubeVirt API.
#
class ManageIQ::Providers::Kubevirt::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  attr_accessor :nodes
  attr_accessor :instance_types
  attr_accessor :vms
  attr_accessor :vm_instances
  attr_accessor :templates

  def initialize(manager, refresh_target)
    super

    @nodes          = @manager.kubeclient.get_nodes
    @instance_types = @manager.kubeclient("instancetype.kubevirt.io/v1beta1").get_virtual_machine_cluster_instancetypes
    @vms            = @manager.kubeclient("kubevirt.io/v1").get_virtual_machines
    @vm_instances   = @manager.kubeclient("kubevirt.io/v1").get_virtual_machine_instances
    @templates      = @manager.kubeclient("template.openshift.io/v1").get_templates
  end
end
