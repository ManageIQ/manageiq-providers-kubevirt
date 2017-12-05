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

require 'kubeclient'
require 'openssl'
require 'ostruct'
require 'rest-client'
require 'uri'

RestClient.log = 'stdout'

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
  # Kubernetes API is created lazily, when needed, so the fact tha this method succeeds does *not*
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
    @host = opts[:host]
    @port = opts[:port]
    @token = opts[:token]
    @namespace = opts[:namespace] || 'default'

    # Prepare the TLS and authentication options that will be used for the standard Kubernetes API
    # and also for the KubeVirt extension:
    @opts = {
      ssl_options: {
        verify_ssl: OpenSSL::SSL::VERIFY_NONE,
      },
      auth_options: {
        bearer_token: @token
      }
    }

    # Kubeclient needs different client objects for different API groups. We will keep in this hash the
    # client objects, indexed by API group/version.
    @clients = {}

    # Nothing else is done here, as this method should never throw an exception, even if the
    # credentials are wrong.
  end

  #
  # Checks if the connection is valid.
  #
  # @return [Boolean] `true` if the connection is valid, `false` otherwise.
  #
  def valid?
    core_client.api_valid?
  end

  #
  # Returns an array containing the nodes available in the Kubernetes cluster.
  #
  # @return [Array] The array of nodes.
  #
  def nodes
    core_client.get_nodes
  end

  #
  # Returns a watcher for nodes.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_nodes(opts = {})
    core_client.watch_nodes(opts)
  end

  #
  # Returns an array containing the virtual machine templates available in the KubeVirt environment.
  #
  # @return [Array] The array of templates.
  #
  def virtual_machine_templates
    kubevirt_client.get_virtual_machine_templates(namespace: @namespace)
  end

  #
  # Retrieves the virtual machine template with the given name.
  #
  # @param name [String] The name of the template.
  # @return [Object] The template object.
  #
  def virtual_machine_template(name)
    kubevirt_client.get_virtual_machine_template(name, @namespace)
  end

  #
  # Returns a watcher for virtual machine templates.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_virtual_machine_templates(opts = {})
    kubevirt_client.watch_virtual_machine_templates(opts)
  end

  #
  # Returns an array containing the stored virtual machines available in the KubeVirt environment.
  #
  # @return [Array] The array of persistent virtual machines.
  #
  def stored_virtual_machines
    kubevirt_client.get_stored_virtual_machines(namespace: @namespace)
  end

  #
  # Retrieves the stored virtual machine with the given name.
  #
  # @param name [String] The name of the virtual machine.
  # @return [Object] The virtual machine object.
  #
  def stored_virtual_machine(name)
    kubevirt_client.get_stored_virtual_machine(name, @namespace)
  end

  #
  # Returns a watcher for stored virtual machines.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_stored_virtual_machines(opts = {})
    kubevirt_client.watch_stored_virtual_machines(opts)
  end

  #
  # Creates a new stored virtual machine.
  #
  # @param vm [Hash] A hash containing the description of the virtual machine.
  #
  def create_stored_virtual_machine(vm)
    kubevirt_client.create_stored_virtual_machine(vm)
  end

  #
  # Returns an array containing the live virtual machines available in the KubeVirt environment.
  #
  # @return [Array] The array of live virtual machines.
  #
  def virtual_machines
    kubevirt_client.get_virtual_machines(namespace: @namespace)
  end

  #
  # Retrieves the live virtual machine with the given name.
  #
  # @param name [String] The name of the virtual machine.
  # @return [Object] The virtual machine object.
  #
  def virtual_machine(name)
    kubevirt_client.get_virtual_machine(name, @namespace)
  end

  #
  # Returns a watcher for live virtual machines.
  #
  # @param opts [Hash] A hash with options for the watcher.
  # @return [Kubeclient::Common::WatchStream] The watcher.
  #
  def watch_virtual_machines(opts = {})
    kubevirt_client.watch_virtual_machines(opts)
  end

  #
  # Creates a new virtual machine.
  #
  # @param vm [Hash] A hash containing the description of the virtual machine.
  #
  def create_virtual_machine(vm)
    kubevirt_client.create_virtual_machine(vm)
  end

  #
  # Calculates the URL of the SPICE proxy server.
  #
  # @return [String] The URL of the spice proxy server.
  #
  def spice_proxy_url
    service = core_client.get_service('spice-proxy', @namespace)
    host = service.spec.externalIPs.first
    port = service.spec.ports.first.port
    url = URI::Generic.build(
      scheme: 'http',
      host: host,
      port: port,
    )
    url.to_s
  end

  private

  #
  # Lazily creates the a client for the given Kubernetes API group and version.
  #
  # @param group [String] The Kubernetes API group.
  # @param version [String] The Kubernetes API version.
  # @return [Kubeclient::Client] The client for the given group and version.
  #
  def client(group, version)
    # Return the client inmediately if it has been created before:
    key = group + '/' + version
    client = @clients[key]
    return client if client

    # Determine the API path:
    if group == CORE_GROUP
      path = '/api'
    else
      path = '/apis/' + group
    end

    # Create the client and save it:
    url = URI::Generic.build(
      scheme: 'https',
      host: @host,
      port: @port,
      path: path
    )
    client = Kubeclient::Client.new(
      url.to_s,
      version,
      @opts
    )
    @clients[key] = client

    # Return the client:
    client
  end

  def core_client
    client(CORE_GROUP, CORE_VERSION)
  end

  def kubevirt_client
    client(KUBEVIRT_GROUP, KUBEVIRT_VERSION)
  end
end
