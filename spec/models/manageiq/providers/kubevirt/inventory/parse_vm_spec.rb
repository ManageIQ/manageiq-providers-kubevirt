#
# Copyright (c) 2018 Red Hat, Inc.
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

require './spec/support/file_helpers'

RSpec.configure do |c|
  c.include FileHelpers
end

describe ManageIQ::Providers::Kubevirt::Inventory::Parser do
  describe '#process_vms' do
    it 'parses a vm' do
      storage_collection = double("storage_collection")
      storage = FactoryGirl.create(:storage)
      allow(storage_collection).to receive(:lazy_find).and_return(storage)

      hw_collection = double("hw_collection")
      hardware = FactoryGirl.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware)

      network_collection = double("network_collection")
      network = FactoryGirl.create(:network, :hardware => hardware)
      allow(network_collection).to receive(:find_or_build_by).and_return(network)
      allow(hardware).to receive(:networks).and_return([network])

      vm_collection = double("vm_collection")
      vm = FactoryGirl.create(:vm_kubevirt, :hardware => hardware)
      allow(vm_collection).to receive(:find_or_build).and_return(vm)

      parser = described_class.new
      parser.instance_variable_set(:@storage_collection, storage_collection)
      parser.instance_variable_set(:@vm_collection, vm_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@network_collection, network_collection)

      source = double("VirtualMachine")
      allow(source).to receive(:uid).and_return("9f3a8f56-1bc8-11e8-a746-001a4a23138b")
      allow(source).to receive(:name).and_return("demo-vm")
      allow(source).to receive(:memory).and_return("64M")
      allow(source).to receive(:cpu_cores).and_return("2")
      allow(source).to receive(:ip_address).and_return("10.128.0.18")
      allow(source).to receive(:node_name).and_return("vm-17-235.eng.lab.tlv.redhat.com")
      allow(source).to receive(:owner_name).and_return(nil)

      parser.send(:process_live_vm, source)
      expect(vm).to have_attributes(
        :name             => "demo-vm",
        :template         => false,
        :ems_ref          => "9f3a8f56-1bc8-11e8-a746-001a4a23138b",
        :ems_ref_obj      => "9f3a8f56-1bc8-11e8-a746-001a4a23138b",
        :uid_ems          => "9f3a8f56-1bc8-11e8-a746-001a4a23138b",
        :vendor           => ManageIQ::Providers::Kubevirt::Constants::VENDOR,
        :power_state      => "on",
        :location         => "unknown",
        :connection_state => "connected",
      )

      net = vm.hardware.networks.first
      expect(net).to_not be_nil
      expect(net.ipaddress).to eq("10.128.0.18")
      expect(net.hostname).to eq("vm-17-235.eng.lab.tlv.redhat.com")
    end
  end
end
