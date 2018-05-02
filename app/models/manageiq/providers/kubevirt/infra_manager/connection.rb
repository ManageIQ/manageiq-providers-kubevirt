#
# Copyright (c) 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'openssl'
require 'ostruct'
require 'rest-client'
require 'uri'

require 'fog/kubevirt'

#
# This class hides the fact that when connecting to KubeVirt we need to use different API servers:
# one for the standard Kubernetes API and another one for the KubeVirt API.
#
class ManageIQ::Providers::Kubevirt::InfraManager::Connection
  #
  # The API version and group of the Kubernetes core:
  #
  CORE_GROUP = ''.freeze
  CORE_VERSION = 'v1'.freeze

  #
  # The API version and group of KubeVirt:
  #
  KUBEVIRT_GROUP = 'kubevirt.io'.freeze
  KUBEVIRT_VERSION = 'v1alpha1'.freeze

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
    # Get options and assign default values:
    @namespace = opts[:namespace] || 'default'
    # create fog based connection
    @conn = Fog::Compute.new(:provider => 'kubevirt',
                             :kubevirt_host => opts[:host],
                             :kubevirt_port => opts[:port],
                             :kubevirt_token => opts[:token],
                             :kubevirt_namespace => @namespace)

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
  # Returns an array containing the offline virtual machines available in the KubeVirt environment.
  #
  # @return [Array] The array of offline virtual machines.
  #
  def offline_vms
    @conn.offlinevms
  end

  #
  # Retrieves the offline virtual machine with the given name.
  #
  # @param name [String] The name of the virtual machine.
  # @return [Object] The virtual machine object.
  #
  def offline_vm(name)
    @conn.offlinevms.get(name)
  end

  #
  # Returns a watcher for offline virtual machines.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_offline_vms(opts = {})
    @conn.watch_offline_vms(opts)
  end

  #
  # Returns an array containing the live virtual machines available in the KubeVirt environment.
  #
  # @return [Array] The array of live virtual machines.
  #
  def live_vms
    @conn.livevms
  end

  #
  # Retrieves the live virtual machine with the given name.
  #
  # @param name [String] The name of the virtual machine.
  # @return [Object] The virtual machine object.
  #
  def live_vm(name)
    @conn.livevms.get(name)
  end

  #
  # Returns a watcher for live virtual machines.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_live_vms(opts = {})
    @conn.watch_live_vms(opts)
  end

  #
  # Deletes a live virtual machine.
  #
  # @param name [String] The name of the virtual machine to delete.
  # @param namespace [String] The namespace where virtual machine is defined.
  #
  def delete_live_vm(name, namespace = nil)
    @conn.livevms.destroy(name, namespace)
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
