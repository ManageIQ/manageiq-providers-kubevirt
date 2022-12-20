#
# This class hides the fact that when connecting to KubeVirt we need to use different API servers:
# one for the standard Kubernetes API and another one for the KubeVirt API.
#
class ManageIQ::Providers::Kubevirt::InfraManager::Connection
  #
  # Creates a new connection with the given options. Note that the actual connection to the
  # Kubernetes API is created lazily, when needed, so the fact that this method succeeds does *not*
  # indicate that the connection parameters are correct.
  #
  # @param opts [Hash] The options used to create the connection.
  #
  # @option opts [String] :host The name of the host of the Kubernetes API server.
  # @option opts [Integer] :port The port number of the Kubernetes API server.
  # @option opts [String] :token The authentication token.
  #
  def initialize(opts = {})
    require 'fog/kubevirt'
    # create fog based connection
    @conn = Fog::Kubevirt::Compute.new(
      :kubevirt_hostname  => opts[:host],
      :kubevirt_port      => opts[:port],
      :kubevirt_token     => opts[:token],
      :kubevirt_namespace => opts[:namespace] || 'default',
      :kubevirt_log       => $log
    )

    # Nothing else is done here, as this method should never throw an exception, even if the
    # credentials are wrong.
  end

  def virt_supported?
    @conn.virt_supported?
  end

  #
  # Checks if the connection is valid.
  #
  # @return [Boolean] `true` if the connection is valid, `false` otherwise.
  #
  def valid?
    @conn.valid?
  end

  #
  # Returns an array containing the nodes available in the Kubernetes cluster.
  #
  # @return [Array] The array of nodes.
  #
  def nodes
    @conn.nodes
  end

  #
  # Returns a watcher for nodes.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_nodes(opts = {})
    @conn.watch_nodes(opts)
  end

  #
  # Returns an array containing the templates available in the KubeVirt environment.
  #
  # @return [Array] The array of templates.
  #
  def templates
    @conn.templates
  end

  #
  # Retrieves the template with the given name.
  #
  # @param name [String] The name of the template.
  # @return [Object] The template object.
  #
  def template(name)
    @conn.templates.get(name)
  end

  #
  # Returns a watcher for templates.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_templates(opts = {})
    @conn.watch_templates(opts)
  end

  #
  # Returns an array containing the virtual machines available in the KubeVirt environment.
  #
  # @return [Array] The array of virtual machines.
  #
  def vms
    @conn.vms
  end

  #
  # Retrieves the virtual machine with the given name.
  #
  # @param name [String] The name of the virtual machine.
  # @return [Object] The virtual machine object.
  #
  def vm(name)
    @conn.vms.get(name)
  end

  #
  # Returns a watcher for virtual machines.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_vms(opts = {})
    @conn.watch_vms(opts)
  end

  #
  # Returns an array containing the virtual machine instances available in the KubeVirt environment.
  #
  # @return [Array] The array of virtual machine instances.
  #
  def vm_instances
    @conn.vminstances
  end

  #
  # Retrieves the virtual machine instance with the given name.
  #
  # @param name [String] The name of the virtual machine.
  # @return [Object] The virtual machine object.
  #
  def vm_instance(name)
    @conn.vminstances.get(name)
  end

  #
  # Returns a watcher for virtual machine instances.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_vm_instances(opts = {})
    @conn.watch_vminstances(opts)
  end

  #
  # Deletes a virtual machine instance.
  #
  # @param name [String] The name of the virtual machine to delete.
  #
  def delete_vm_instance(name, namespace)
    @conn.vminstances.destroy(name, namespace)
  end

  #
  # Calculates the URL of the SPICE proxy server.
  #
  # @return [String] The URL of the spice proxy server.
  #
  def spice_proxy_url
    @conn.spice_proxy_url
  end
end
