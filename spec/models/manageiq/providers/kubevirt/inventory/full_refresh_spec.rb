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

require 'json'
require 'recursive_open_struct'

describe ManageIQ::Providers::Kubevirt::Inventory::Parser::FullRefresh do
  describe '#parse' do
    it 'works correctly with one node' do
      # Run the parser:
      manager = create_manager('one_node')
      inventory = ManageIQ::Providers::Kubevirt::Inventory.build(manager, nil)

      expect(inventory.parsers.first.class).to eq(described_class)
      inventory.parse

      persister = inventory.persister
      persister.persist!

      # Check that the built-in objects have been added:
      check_builtin_clusters(persister)
      check_builtin_storages(persister)

      # Check that the collection of hosts has been created:
      hosts_collection = persister.collections[:hosts]
      expect(hosts_collection).to_not be_nil
      hosts_data = hosts_collection.data
      expect(hosts_data).to_not be_nil
      expect(hosts_data.length).to eq(1)

      # Check that the first host has been created:
      host = hosts_data.first
      expect(host).to_not be_nil
      expect(host.connection_state).to eq('connected')
      expect(host.ems_ref).to eq('d88c7af6-de6a-11e7-8725-52540080f1d2')
      expect(host.hostname).to eq('mynode.local')
      expect(host.ipaddress).to eq('192.168.122.40')
      expect(host.name).to eq('mynode')
      expect(host.type).to eq('ManageIQ::Providers::Kubevirt::InfraManager::Host')
      expect(host.uid_ems).to eq('d88c7af6-de6a-11e7-8725-52540080f1d2')
      expect(host.vmm_product).to eq('KubeVirt')
      expect(host.vmm_vendor).to eq('kubevirt')
      expect(host.vmm_version).to eq('0.1.0')
      expect(host.ems_cluster).to_not be_nil
    end
  end

  private

  #
  # Creates a manager double.
  #
  # @return [Object] The manager object.
  #
  def create_manager(file_name)
    FactoryBot.create(:ems_kubevirt, :name => "mykubevirt").tap do |manager|
      allow(manager).to receive(:with_provider_connection).and_yield(json_data(file_name))
    end
  end

  #
  # Creates a collector data from a JSON file. The file should be in the `spec/fixtures/files/collectors`
  # directory of the project. The name should be the given name followed by `.json`. The content of
  # the JSON file should be an object like this:
  #
  #     {
  #        "nodes": [...],
  #        "vms": [...],
  #        "vm_instances": [...],
  #        "templates": [...]
  #     }
  #
  # The elements of these arrays should be the JSON representation of objects extracted from the
  # Kubernetes API. A simple way to obtain it this, for example for a node:
  #
  #     kubectl get node mynode -o json
  #
  def json_data(name)
    # Load the data and convert it to recursive open struct:
    data = file_fixture("collectors/#{name}.json").read
    data = YAML.safe_load(data)
    RecursiveOpenStruct.new(data, :recurse_over_arrays => true)
  end

  #
  # Checks that the expected built-in cluster has been added to the clusters collection.
  #
  # @param persister [Object] The populated persister.
  #
  def check_builtin_clusters(persister)
    # Check that the collection of clusters has been created:
    collection = persister.collections[:clusters]
    expect(collection).to_not be_nil
    data = collection.data
    expect(data).to_not be_nil
    expect(data.length).to eq(1)

    # Check that the built-in cluster has been created:
    cluster = data.first
    expect(cluster).to_not be_nil
    expect(cluster.ems_ref).to eq('0')
    expect(cluster.name).to eq('mykubevirt')
    expect(cluster.uid_ems).to eq('0')
  end

  #
  # Checks that the expected built-in storage has been added to the storages collection.
  #
  # @param persister [Object] The populated persister.
  #
  def check_builtin_storages(persister)
    # Check that the collection of storages has been created:
    collection = persister.collections[:storages]
    expect(collection).to_not be_nil
    data = collection.data
    expect(data).to_not be_nil
    expect(data.length).to eq(1)

    # Check that the builtin storage has been created:
    storage = data.first
    expect(storage).to_not be_nil
    expect(storage.ems_ref).to eq('0')
    expect(storage.name).to eq('mykubevirt')
    expect(storage.store_type).to eq('UNKNOWN')
  end
end
