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

    @manager.with_provider_connection(:namespace => @target.location) do |connection|
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
    @nodes        = kube_client.get_nodes
    @vms          = kubevirt_client.get_virtual_machines
    @vm_instances = kubevirt_client.get_virtual_machine_instances
    @templates    = openshift_template_client.get_templates
  end

  def kube_client(api_group = nil)
    api_path, api_version = api_group&.split("/")

    options = {:service => "kubernetes"}
    options.merge!(:path => "/apis/#{api_path}", :version => api_version) if api_path

    @manager.parent_manager.connect(options)
  end

  def kubevirt_client
    @kubevirt_client ||= kube_client("kubevirt.io/v1")
  end

  def openshift_template_client
    @openshift_template_client ||= kube_client("template.openshift.io/v1")
  end
end
