require 'json'
require 'recursive_open_struct'

describe ManageIQ::Providers::Kubevirt::Inventory::Parser::FullRefresh do
  describe '#parse' do
    let(:ems) do
      FactoryBot.create(:ems_kubevirt, :name => "mykubevirt").tap do |manager|
        allow(manager).to receive(:with_provider_connection).and_yield(json_data('one_node'))
      end
    end

    it 'works correctly with one node' do
      2.times do
        EmsRefresh.refresh(ems)

        expect(ems.hosts.count).to eq(1)
        expect(ems.clusters.count).to eq(1)
        expect(ems.storages.count).to eq(1)

        # Check that the first host has been created:
        host = ems.hosts.find_by(:ems_ref => "d88c7af6-de6a-11e7-8725-52540080f1d2")
        expect(host).to have_attributes(
          :connection_state => "connected",
          :ems_ref          => "d88c7af6-de6a-11e7-8725-52540080f1d2",
          :hostname         => "mynode.local",
          :ipaddress        => "192.168.122.40",
          :name             => "mynode",
          :type             => "ManageIQ::Providers::Kubevirt::InfraManager::Host",
          :uid_ems          => "d88c7af6-de6a-11e7-8725-52540080f1d2",
          :vmm_product      => "KubeVirt",
          :vmm_vendor       => "kubevirt",
          :vmm_version      => "0.1.0",
          :ems_cluster      => ems.ems_clusters.find_by(:ems_ref => "0")
        )

        cluster = ems.ems_clusters.find_by(:ems_ref => "0")
        expect(cluster).to have_attributes(
          :ems_ref => "0",
          :name    => "mykubevirt",
          :uid_ems => "0",
          :type    => "ManageIQ::Providers::Kubevirt::InfraManager::Cluster"
        )

        storage = ems.storages.find_by(:ems_ref => "0")
        expect(storage).to have_attributes(
          :name        => "mykubevirt",
          :total_space => 0,
          :free_space  => 0,
          :ems_ref     => "0",
          :type        => "ManageIQ::Providers::Kubevirt::InfraManager::Storage"
        )
      end
    end
  end

  private

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
