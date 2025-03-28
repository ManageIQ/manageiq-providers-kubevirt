#
# This class contains the data needed to perform a refresh. The data are the collections of nodes, virtual machines and
# templates retrieved using the KubeVirt API.
#
# Note that unlike other typical collectors it doesn't really retrieve that data itself: the refresh worker will create
# with the data that it already obtained from the KubeVirt API.
#
class ManageIQ::Providers::Kubevirt::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  attr_accessor :nodes
  attr_accessor :vms
  attr_accessor :vm_instances
  attr_accessor :templates
  attr_accessor :snapshots

  def initialize(manager, refresh_target)
    super

    if refresh_target.kind_of?(ManageIQ::Providers::Kubevirt::InfraManager::Vm)
      initialize_for_targeted_refresh
    else
      initialize_for_full_refresh
    end
  end

  protected

  def initialize_for_targeted_refresh
    name = @target.name
    namespace = @target.location
    @nodes = {}

    if @target.template?
      @templates = [@manager.kubeclient("template.openshift.io/v1").template(name, namespace)]
    else
      @vms = [@manager.kubeclient("kubevirt.io/v1").get_virtual_machine(name, namespace)]
      begin
        @vm_instances = [@manager.kubeclient("kubevirt.io/v1")..get_virtual_machine_instance(name, namespace)]
      rescue
        # target refresh of a vm might fail if it has no vm instance
        _log.debug("The is no running vm resource for '#{name}'")
      end
      @snapshots = [] # TODO get all snapshots for this one vm
    end
  end

  def initialize_for_full_refresh
    @nodes = @manager.kubeclient.get_nodes
    @vms = @manager.kubeclient("kubevirt.io/v1").get_virtual_machines
    @vm_instances = @manager.kubeclient("kubevirt.io/v1").get_virtual_machine_instances
    @templates = @manager.kubeclient("template.openshift.io/v1").get_templates
    @snapshots = @manager.kubeclient("snapshot.kubevirt.io/v1beta1").get_virtual_machine_snapshots
  end
end
