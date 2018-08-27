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

#
# This is the base class for all the rest of the parsers. It contains the methods that will be
# shared by the full and targeted refresh parsers.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser < ManageIQ::Providers::Inventory::Parser
  include Vmdb::Logging
  require 'fog/kubevirt'

  protected

  #
  # The identifier of the built-in cluster:
  #
  CLUSTER_ID = '0'.freeze

  #
  # The identifier of the built-in storage:
  #
  STORAGE_ID = '0'.freeze

  attr_reader :cluster_collection
  attr_reader :host_collection
  attr_reader :host_storage_collection
  attr_reader :hw_collection
  attr_reader :network_collection
  attr_reader :os_collection
  attr_reader :storage_collection
  attr_reader :template_collection
  attr_reader :vm_collection
  attr_reader :vm_os_collection
  attr_reader :disk_collection

  def add_builtin_clusters
    cluster_object = cluster_collection.find_or_build(CLUSTER_ID)
    cluster_object.ems_ref = CLUSTER_ID
    cluster_object.ems_ref_obj = CLUSTER_ID
    cluster_object.name = collector.manager.name
    cluster_object.uid_ems = CLUSTER_ID
  end

  def add_builtin_storages
    storage_object = storage_collection.find_or_build(STORAGE_ID)
    storage_object.ems_ref = STORAGE_ID
    storage_object.ems_ref_obj = STORAGE_ID
    storage_object.name = collector.manager.name
    storage_object.store_type = 'UNKNOWN'
    storage_object.total_space = 0
    storage_object.free_space = 0
    storage_object.uncommitted = 0
  end

  def process_nodes(objects)
    objects.each do |object|
      process_node(object)
    end
  end

  def process_node(object)
    # Get the basic information:
    uid = object.uid
    name = object.name

    # Add the inventory object for the host:
    host_object = host_collection.find_or_build(uid)
    host_object.connection_state = 'connected'
    host_object.ems_cluster = cluster_collection.lazy_find(CLUSTER_ID)
    host_object.ems_ref = uid
    host_object.ems_ref_obj = uid
    host_object.hostname = object.hostname
    host_object.ipaddress = object.ip_address
    host_object.name = name
    host_object.type = ::Host.name
    host_object.uid_ems = uid
    host_object.vmm_product = ManageIQ::Providers::Kubevirt::Constants::PRODUCT
    host_object.vmm_vendor = ManageIQ::Providers::Kubevirt::Constants::VENDOR
    host_object.vmm_version = ManageIQ::Providers::Kubevirt::Constants::VERSION

    # Add the inventory object for the operating system details:
    os_object = os_collection.find_or_build(host_object)
    os_object.name = object.hostname
    os_object.product_name = object.os_image
    os_object.product_type = object.operating_system
    os_object.version = object.kernel_version

    # Find the storage:
    storage_object = storage_collection.lazy_find(STORAGE_ID)

    # Add the inventory object for the host storage:
    host_storage_collection.find_or_build_by(
      :host    => host_object,
      :storage => storage_object,
    )
  end

  def process_vms(objects)
    objects.each do |object|
      process_vm(object)
    end
  end

  def process_vm(object)
    # Process the domain:
    vm_object = process_domain(object.memory, object.cpu_cores, object.uid, object.name)

    # Add the inventory object for the OperatingSystem
    process_os(vm_object, object.labels, object.annotations)

    # The power status is initially off, it will be set to on later if the virtual machine instance exists:
    vm_object.raw_power_state = 'Succeeded'
  end

  def process_vm_instances(objects)
    objects.each do |object|
      process_vm_instance(object)
    end
  end

  def process_vm_instance(object)
    # Get the basic information:
    uid = object.uid
    name = object.name

    # Get the identifier of the virtual machine from the owner reference:
    unless object.owner_name.nil?
      # seems like valid use case for now
      uid = object.owner_uid
      name = object.owner_name
    end

    # Process the domain:
    vm_object = process_domain(object.memory, object.cpu_cores, uid, name)
    process_status(vm_object, object.ip_address, object.node_name)

    vm_object.raw_power_state = object.status
  end

  def process_domain(memory, cores, uid, name)
    # Find the storage:
    storage_object = storage_collection.lazy_find(STORAGE_ID)
    # Create the inventory object for the virtual machine:
    vm_object = vm_collection.find_or_build(uid)
    vm_object.connection_state = 'connected'
    vm_object.ems_ref = uid
    vm_object.ems_ref_obj = uid
    vm_object.name = name
    vm_object.storage = storage_object
    vm_object.storages = [storage_object]
    vm_object.template = false
    vm_object.type = ::ManageIQ::Providers::Kubevirt::InfraManager::Vm.name
    vm_object.uid_ems = uid
    vm_object.vendor = ManageIQ::Providers::Kubevirt::Constants::VENDOR
    vm_object.location = 'unknown'

    # Create the inventory object for the hardware:
    hw_object = hw_collection.find_or_build(vm_object)
    hw_object.memory_mb = ManageIQ::Providers::Kubevirt::MemoryCalculator.convert(memory, 'Mi')
    hw_object.cpu_cores_per_socket = cores
    hw_object.cpu_total_cores = cores

    # Return the created inventory object:
    vm_object
  end

  def process_status(vm_object, ip_address, node_name)
    hw_object = hw_collection.find_or_build(vm_object)

    # Create the inventory object for vm network device
    hardware_networks(hw_object, ip_address, node_name)
  end

  def hardware_networks(hw_object, ip_address, node_name)
    return nil unless ip_address

    network_collection.find_or_build_by(
      :hardware  => hw_object,
      :ipaddress => ip_address,
    ).assign_attributes(
      :ipaddress => ip_address,
      :hostname  => node_name
    )
  end

  def process_templates(objects)
    objects.each do |object|
      process_template(object)
    end
  end

  def process_template(object)
    # Get the basic information:
    uid = object.uid

    # Add the inventory object for the template:
    template_object = template_collection.find_or_build(uid)
    template_object.connection_state = 'connected'
    template_object.ems_ref = uid
    template_object.ems_ref_obj = uid
    template_object.name = object.name
    template_object.raw_power_state = 'never'
    template_object.template = true
    template_object.type = ::ManageIQ::Providers::Kubevirt::InfraManager::Template.name
    template_object.uid_ems = uid
    template_object.vendor = ManageIQ::Providers::Kubevirt::Constants::VENDOR
    template_object.location = 'unknown'

    vm = vm_from_objects(object.objects)

    # Add the inventory object for the hardware:
    process_hardware(template_object, object.parameters, object.labels, vm.dig(:spec, :template, :spec, :domain))

    # Add the inventory object for the OperatingSystem
    process_os(template_object, object.labels, object.annotations)
  end

  def vm_from_objects(objects)
    vm = nil
    objects.each do |object|
      if object[:kind] == "VirtualMachine"
        vm = object
      end
    end
    vm
  end

  def process_hardware(template_object, params, labels, domain)
    hw_object = hw_collection.find_or_build(template_object)
    memory = default_value(params, 'MEMORY') || domain.dig(:resources, :requests, :memory)
    hw_object.memory_mb = ManageIQ::Providers::Kubevirt::MemoryCalculator.convert(memory, 'Mi')
    cpu = default_value(params, 'CPU_CORES') || domain.dig(:cpu, :cores)
    hw_object.cpu_cores_per_socket = cpu
    hw_object.cpu_total_cores = cpu
    hw_object.guest_os = labels&.dig(Fog::Compute::Kubevirt::Shared::OS_LABEL_SYMBOL)

    # Add the inventory objects for the disk:
    process_disks(hw_object, domain)
  end

  def default_value(params, name)
    name_param = params.detect { |param| param[:name] == name }
    name_param[:value] if name_param
  end

  def process_disks(hw_object, domain)
    domain.dig(:devices, :disks).each do |disk|
      disk_object = disk_collection.find_or_build_by(
        :hardware    => hw_object,
        :device_name => disk[:name]
      )
      disk_object.device_name = disk[:name]
      disk_object.location = disk[:volumeName]
      disk_object.device_type = 'disk'
      disk_object.present = true
      disk_object.mode = 'persistent'
      # TODO: what do we need more? We are missing reference to PV or PVC
    end
  end

  def process_os(template_object, labels, annotations)
    os_object = vm_os_collection.find_or_build(template_object)
    os_object.product_name = labels&.dig(Fog::Compute::Kubevirt::Shared::OS_LABEL_SYMBOL)
    tags = annotations&.dig(:tags) || []
    os_object.product_type = if tags.include?("linux")
                               "linux"
                             elsif tags.include?("windows")
                               "windows"
                             else
                               "other"
                             end
  end
end
