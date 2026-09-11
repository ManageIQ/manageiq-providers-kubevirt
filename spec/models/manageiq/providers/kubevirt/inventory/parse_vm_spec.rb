require './spec/support/file_helpers'

RSpec.configure do |c|
  c.include FileHelpers
end

describe ManageIQ::Providers::Kubevirt::Inventory::Parser do
  describe '#process_vm_instance' do
    it 'parses a vm instance including disks' do
      host_collection = double("host_collection")
      host = FactoryBot.create(:host)
      allow(host_collection).to receive(:lazy_find).and_return(host)

      disk_collection = double("disk_collection")
      disk = FactoryBot.create(:disk)
      cdrom_disk = FactoryBot.create(:disk)
      allow(disk_collection).to receive(:find_or_build_by).and_return(disk, cdrom_disk)

      hw_collection = double("hw_collection")
      hardware = FactoryBot.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware)

      network_collection = double("network_collection")
      network1 = FactoryBot.create(:network, :hardware => hardware, :ipaddress => "10.128.0.18")
      network2 = FactoryBot.create(:network, :hardware => hardware, :ipaddress => "192.168.1.5")
      [network1, network2].each do |n|
        allow(n).to receive(:assign_attributes) { |attrs| n.update_columns(attrs) }
      end
      allow(network_collection).to receive(:find_or_build_by).and_return(network1, network2)

      vm_collection = double("vm_collection")
      vm = FactoryBot.create(:vm_kubevirt, :hardware => hardware)
      allow(vm_collection).to receive(:find_or_build).and_return(vm)

      collector = double("collector")
      allow(collector).to receive(:pvc).and_return(nil)

      parser = described_class.new
      parser.instance_variable_set(:@host_collection, host_collection)
      parser.instance_variable_set(:@vm_collection, vm_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@network_collection, network_collection)
      parser.instance_variable_set(:@disk_collection, disk_collection)
      parser.instance_variable_set(:@collector, collector)

      source = unprocessed_object("vmi.json")

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

      expect(vm.hardware.networks.count).to eq(2)

      network1.reload
      expect(network1.hostname).to eq("vm-17-235.eng.lab.tlv.redhat.com")
      expect(network1.subnet_mask).to be_nil

      # Second interface has a CIDR suffix — verify it is stripped and subnet_mask derived
      network2.reload
      expect(network2.hostname).to eq("vm-17-235.eng.lab.tlv.redhat.com")
      expect(network2.subnet_mask).to eq("255.255.255.0")

      expect(disk).to have_attributes(
        :device_name     => "pvcvolume",
        :device_type     => "disk",
        :present         => true,
        :mode            => "persistent",
        :controller_type => "sata",
        :bootable        => true,
        :filename        => "demo-vm-tinycore",
        :location        => "demo-vm-tinycore",
        :size            => 10 * 1024 * 1024 * 1024,
        :size_on_disk    => 5_368_709_120,
        :disk_type       => "thick",
        :thin            => false,
        :ems_ref         => "pvcvolume"
      )

      expect(cdrom_disk).to have_attributes(
        :device_name => "cdromdisk",
        :device_type => "cdrom",
        :present     => true,
        :mode        => "persistent",
        :ems_ref     => "cdromdisk"
      )
    end
  end

  describe '#process_vm' do
    it 'parses a vm including disks' do
      disk_collection = double("disk_collection")
      disk = FactoryBot.create(:disk)
      allow(disk_collection).to receive(:find_or_build_by).and_return(disk)

      hw_collection = double("hw_collection")
      hardware = FactoryBot.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware)

      vm_os_collection = double("vm_os_collection")
      os = FactoryBot.create(:operating_system)
      allow(vm_os_collection).to receive(:find_or_build).and_return(os)

      flavor_collection = double("flavor_collection")

      vm_collection = double("vm_collection")
      vm = FactoryBot.create(:vm_kubevirt, :hardware => hardware)
      allow(vm_collection).to receive(:find_or_build).and_return(vm)

      # Build a PVC stub that provides data for the stopped VM (no vol_status)
      pvc = RecursiveOpenStruct.new(
        {
          :metadata => {:name => "demo-vm-rootdisk"},
          :spec     => {
            :volumeMode => "Filesystem",
            :resources  => {:requests => {:storage => "10Gi"}}
          },
          :status   => {:capacity => {:storage => "10Gi"}}
        },
        :recurse_over_arrays => true
      )

      collector = double("collector")
      allow(collector).to receive(:pvc).and_return(nil)
      allow(collector).to receive(:pvc).with("demo-vm-rootdisk", "default").and_return(pvc)

      parser = described_class.new
      parser.instance_variable_set(:@vm_collection, vm_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@disk_collection, disk_collection)
      parser.instance_variable_set(:@vm_os_collection, vm_os_collection)
      parser.instance_variable_set(:@flavor_collection, flavor_collection)
      parser.instance_variable_set(:@collector, collector)

      source = unprocessed_object("vm.json")

      parser.send(:process_vm, source)

      expect(vm).to have_attributes(
        :name             => "demo-vm",
        :template         => false,
        :ems_ref          => "9f3a8f56-1bc8-11e8-a746-001a4a23138b",
        :uid_ems          => "9f3a8f56-1bc8-11e8-a746-001a4a23138b",
        :vendor           => ManageIQ::Providers::Kubevirt::Constants::VENDOR,
        :power_state      => "off",
        :location         => "default",
        :connection_state => "connected"
      )

      expect(disk).to have_attributes(
        :device_name     => "rootdisk",
        :device_type     => "disk",
        :present         => true,
        :mode            => "persistent",
        :controller_type => "virtio",
        :bootable        => true,
        :filename        => "demo-vm-rootdisk",
        :location        => "demo-vm-rootdisk",
        :size            => 10 * 1024 * 1024 * 1024,
        :disk_type       => "thin",
        :thin            => true,
        :ems_ref         => "rootdisk"
      )
    end
  end
  describe '#process_template' do
    it 'parses a template including disk size resolved from dataVolumeTemplates' do
      disk_collection = double("disk_collection")
      rootdisk = FactoryBot.create(:disk)
      cloudinitdisk = FactoryBot.create(:disk)
      allow(disk_collection).to receive(:find_or_build_by).and_return(rootdisk, cloudinitdisk)

      hw_collection = double("hw_collection")
      hardware = FactoryBot.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware)

      vm_os_collection = double("vm_os_collection")
      os = FactoryBot.create(:operating_system)
      allow(vm_os_collection).to receive(:find_or_build).and_return(os)

      template_collection = double("template_collection")
      template = FactoryBot.create(:template_kubevirt, :hardware => hardware)
      allow(template_collection).to receive(:find_or_build).and_return(template)

      # No PVCs — the template uses ${NAME} placeholders so no real PVC exists yet
      collector = double("collector")
      allow(collector).to receive(:pvc).and_return(nil)

      parser = described_class.new
      parser.instance_variable_set(:@template_collection, template_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@disk_collection, disk_collection)
      parser.instance_variable_set(:@vm_os_collection, vm_os_collection)
      parser.instance_variable_set(:@collector, collector)

      source = unprocessed_object("template.json")

      parser.send(:process_template, source)

      expect(template).to have_attributes(
        :name             => "example",
        :template         => true,
        :ems_ref          => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :uid_ems          => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :location         => "default",
        :connection_state => "connected"
      )

      # rootdisk: size from dataVolumeTemplates, filename/location nil (${NAME} is a placeholder)
      expect(rootdisk).to have_attributes(
        :device_name     => "rootdisk",
        :device_type     => "disk",
        :present         => true,
        :mode            => "persistent",
        :controller_type => "virtio",
        :bootable        => true,
        :size            => 30 * 1024 * 1024 * 1024,
        :filename        => nil,
        :location        => nil,
        :ems_ref         => "rootdisk"
      )

      # cloudinitdisk has no dataVolume or PVC — size remains nil
      expect(cloudinitdisk).to have_attributes(
        :device_name => "cloudinitdisk",
        :device_type => "disk",
        :present     => true,
        :mode        => "persistent",
        :size        => nil,
        :ems_ref     => "cloudinitdisk"
      )
    end
  end
end
