require './spec/support/file_helpers'

RSpec.configure do |c|
  c.include FileHelpers
end

describe ManageIQ::Providers::Kubevirt::Inventory::Parser do
  describe '#process_vms' do
    it 'parses a vm' do
      storage_collection = double("storage_collection")
      storage = FactoryBot.create(:storage)
      allow(storage_collection).to receive(:lazy_find).and_return(storage)

      host_collection = double("host_collection")
      host = FactoryBot.create(:host)
      allow(host_collection).to receive(:lazy_find).and_return(host)

      hw_collection = double("hw_collection")
      hardware = FactoryBot.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware)

      network_collection = double("network_collection")
      network = FactoryBot.create(:network, :hardware => hardware)
      allow(network_collection).to receive(:find_or_build_by).and_return(network)
      allow(hardware).to receive(:networks).and_return([network])

      vm_collection = double("vm_collection")
      vm = FactoryBot.create(:vm_kubevirt, :hardware => hardware)
      allow(vm_collection).to receive(:find_or_build).and_return(vm)

      parser = described_class.new
      parser.instance_variable_set(:@storage_collection, storage_collection)
      parser.instance_variable_set(:@host_collection, host_collection)
      parser.instance_variable_set(:@vm_collection, vm_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@network_collection, network_collection)

      source = unprocessed_object("vm.json")

      parser.send(:process_vm_instance, source)
      expect(vm).to have_attributes(
        :name             => "demo-vm",
        :template         => false,
        :ems_ref          => "9f3a8f56-1bc8-11e8-a746-001a4a23138b",
        :uid_ems          => "9f3a8f56-1bc8-11e8-a746-001a4a23138b",
        :vendor           => ManageIQ::Providers::Kubevirt::Constants::VENDOR,
        :power_state      => "on",
        :location         => "default",
        :connection_state => "connected",
      )
      expect(vm.host).to eq(host)

      net = vm.hardware.networks.first
      expect(net).to_not be_nil
      expect(net.ipaddress).to eq("10.128.0.18")
      expect(net.hostname).to eq("vm-17-235.eng.lab.tlv.redhat.com")
    end
  end
end
