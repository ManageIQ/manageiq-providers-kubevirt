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
  describe '#process_templates' do
    it 'parses a template' do
      disk_collection = double("disk_collection")
      disk = FactoryBot.create(:disk)
      allow(disk_collection).to receive(:find_or_build_by).and_return(disk)

      hw_collection = double("hw_collection")
      hardware = FactoryBot.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware, :disks => [disk])

      os_collection = double("os_collection")
      os = FactoryBot.create(:operating_system)
      allow(os_collection).to receive(:find_or_build).and_return(os)

      template_collection = double("template_collection")
      temp = FactoryBot.create(:template_kubevirt, :hardware => hardware, :operating_system => os)
      allow(template_collection).to receive(:find_or_build).and_return(temp)

      parser = described_class.new
      parser.instance_variable_set(:@template_collection, template_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@vm_os_collection, os_collection)
      parser.instance_variable_set(:@disk_collection, disk_collection)

      json = unprocessed_object("template.json")

      source = double(
        :name        => "example",
        :uid         => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :objects     => json.objects,
        :parameters  => json.parameters,
        :labels      => json.metadata.labels,
        :annotations => json.metadata.annotations
      )

      parser.send(:process_template, source)

      expect(temp).to have_attributes(
        :name             => "example",
        :template         => true,
        :ems_ref          => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :uid_ems          => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :vendor           => ManageIQ::Providers::Kubevirt::Constants::VENDOR,
        :power_state      => "never",
        :location         => "unknown",
        :connection_state => "connected",
      )

      expect(temp.hardware).to have_attributes(
        :guest_os             => "rhel-7",
        :cpu_cores_per_socket => 4,
        :cpu_total_cores      => 4,
        :memory_mb            => 4096
      )

      expect(temp.operating_system).to have_attributes(
        :product_name => "rhel-7",
        :product_type => "linux"
      )

      expect(disk).to have_attributes(
        :device_name => "disk0-pvc",
        :device_type => "disk",
        :present     => true,
        :mode        => "persistent"
      )
    end

    it "parses a template with registry disk" do
      disk_collection = double("disk_collection")
      disk1 = FactoryBot.create(:disk)
      disk2 = FactoryBot.create(:disk)
      allow(disk_collection).to receive(:find_or_build_by).and_return(disk1, disk2)

      hw_collection = double("hw_collection")
      hardware = FactoryBot.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware, :disks => [disk1, disk2])

      os_collection = double("os_collection")
      os = FactoryBot.create(:operating_system)
      allow(os_collection).to receive(:find_or_build).and_return(os)

      template_collection = double("template_collection")
      temp = FactoryBot.create(:template_kubevirt, :hardware => hardware, :operating_system => os)
      allow(template_collection).to receive(:find_or_build).and_return(temp)

      parser = described_class.new
      parser.instance_variable_set(:@template_collection, template_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@vm_os_collection, os_collection)
      parser.instance_variable_set(:@disk_collection, disk_collection)

      json = unprocessed_object("template_registry.json")

      source = double(
        :name        => "working",
        :uid         => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :objects     => json.objects,
        :parameters  => json.parameters,
        :labels      => json.metadata.labels,
        :annotations => json.metadata.annotations
      )

      parser.send(:process_template, source)

      expect(disk1).to have_attributes(
        :device_name => "registryvolume",
        :device_type => "disk",
        :present     => true,
        :mode        => "persistent"
      )

      expect(disk2).to have_attributes(
        :device_name => "cloudinitvolume",
        :device_type => "disk",
        :present     => true,
        :mode        => "persistent"
      )
    end

    it 'parses a template without parameters' do
      disk_collection = double("disk_collection")
      disk = FactoryBot.create(:disk)
      allow(disk_collection).to receive(:find_or_build_by).and_return(disk)

      hw_collection = double("hw_collection")
      hardware = FactoryBot.create(:hardware)
      allow(hw_collection).to receive(:find_or_build).and_return(hardware, :disks => [disk])

      os_collection = double("os_collection")
      os = FactoryBot.create(:operating_system)
      allow(os_collection).to receive(:find_or_build).and_return(os)

      template_collection = double("template_collection")
      temp = FactoryBot.create(:template_kubevirt, :hardware => hardware, :operating_system => os)
      allow(template_collection).to receive(:find_or_build).and_return(temp)

      parser = described_class.new
      parser.instance_variable_set(:@template_collection, template_collection)
      parser.instance_variable_set(:@hw_collection, hw_collection)
      parser.instance_variable_set(:@vm_os_collection, os_collection)
      parser.instance_variable_set(:@disk_collection, disk_collection)

      json = unprocessed_object("template-without-parameters.yml")

      source = double(
        :name        => "template-without-parameters",
        :uid         => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :objects     => json.objects,
        :parameters  => json.parameters,
        :labels      => json.metadata.labels,
        :annotations => json.metadata.annotations
      )

      parser.send(:process_template, source)

      expect(temp).to have_attributes(
        :name             => "template-without-parameters",
        :template         => true,
        :ems_ref          => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :uid_ems          => "7e6fb1ac-00ef-11e8-8840-525400b2cba8",
        :vendor           => ManageIQ::Providers::Kubevirt::Constants::VENDOR,
        :power_state      => "never",
        :location         => "unknown",
        :connection_state => "connected",
      )

      expect(temp.hardware).to have_attributes(
        :guest_os             => "fedora28",
        :cpu_cores_per_socket => 2,
        :cpu_total_cores      => 2,
        :memory_mb            => 1024
      )

      expect(temp.operating_system).to have_attributes(
        :product_name => "fedora28",
        :product_type => "linux"
      )

      expect(disk).to have_attributes(
        :device_name => "cloudinitvolume",
        :device_type => "disk",
        :present     => true,
        :mode        => "persistent"
      )
    end
  end
end
