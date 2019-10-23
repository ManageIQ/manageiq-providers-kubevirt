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

describe ManageIQ::Providers::Kubevirt::Inventory::Parser::PartialTargetRefresh do
  describe '#parse' do
    it 'works correctly with one node' do
      # Run the parser:
      manager = create_manager('one_vm')
      collector = ManageIQ::Providers::Kubevirt::Inventory.collector_class_for(manager, nil).new(manager, nil)
      persister = ManageIQ::Providers::Kubevirt::Inventory.persister_class_for(manager, nil).new(manager, nil)
      inventory = ManageIQ::Providers::Kubevirt::Inventory.new(persister,
                                                               collector,
                                                               [described_class.new])
      inventory.parse

      # Check that the built-in objects have been added:
      check_builtin_clusters(persister)
      check_builtin_storages(persister)

      # Check that the collection of vms has been created:
      vm_collection = persister.collections[:vms]
      expect(vm_collection).to_not be_nil
      vms_data = vm_collection.data
      expect(vms_data).to_not be_nil
      expect(vms_data.length).to eq(1)

      # Check that the first vm has been created:
      vm = vms_data.first
      expect(vm).to_not be_nil
      expect(vm.connection_state).to eq('connected')
      expect(vm.ems_ref).to eq('afd81ba1-279d-11e8-b7f0-52540043c7f7')
      expect(vm.ems_ref_obj).to eq('afd81ba1-279d-11e8-b7f0-52540043c7f7')
      expect(vm.name).to eq('2cores1024mem')
      expect(vm.type).to eq('ManageIQ::Providers::Kubevirt::InfraManager::Vm')
      expect(vm.uid_ems).to eq('afd81ba1-279d-11e8-b7f0-52540043c7f7')
      expect(vm.template).to be false

      vms_hardware = persister.collections[:hardwares]
      expect(vms_hardware).to_not be_nil
      vms_hardware_data = vms_hardware.data
      expect(vms_hardware_data).to_not be_nil
      expect(vms_hardware_data.length).to eq(1)
      vm_hardware = vms_hardware.data.first
      expect(vm_hardware).to_not be_nil
      expect(vm_hardware.memory_mb.to_s).to eq('1024.0')
      expect(vm_hardware.cpu_cores_per_socket).to eq(2)
      expect(vm_hardware.cpu_total_cores).to eq(2)
    end
  end

  private

  #
  # Creates a manager double.
  #
  # @return [Object] The manager object.
  #
  def create_manager(file_name)
    manager = double
    allow(manager).to receive(:name).and_return('mykubevirt')
    allow(manager).to receive(:id).and_return(0)
    allow(manager.class).to receive(:ems_type).and_return(::ManageIQ::Providers::Kubevirt::Constants::VENDOR)
    allow(manager).to receive(:with_provider_connection).and_yield(json_data(file_name))
    manager
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
    expect(cluster.ems_ref_obj).to eq('0')
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
    expect(storage.ems_ref_obj).to eq('0')
    expect(storage.name).to eq('mykubevirt')
    expect(storage.store_type).to eq('UNKNOWN')
  end
end
