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
    @nodes = {}

    @manager.with_provider_connection do |connection|
      if @target.template?
        @templates = [connection.template(name)]
      else
        @vms = [connection.vm(name)]
        begin
          @vm_instances = [connection.vm_instance(name)]
        rescue
          # target refresh of a vm might fail if it has no vm instance
          _log.debug("The is no running vm resource for '#{name}'")
        end
      end
    end
  end

  def initialize_for_full_refresh
    @manager.with_provider_connection do |connection|
      @nodes = connection.nodes
      @vms = connection.vms
      @vm_instances = connection.vm_instances
      @templates = connection.templates
    end
  end
end
