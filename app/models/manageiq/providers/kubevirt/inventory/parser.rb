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
class ManageIQ::Providers::Kubevirt::Inventory::Parser < ManagerRefresh::Inventory::Parser
  include Vmdb::Logging

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
  attr_reader :os_collection
  attr_reader :storage_collection
  attr_reader :template_collection
  attr_reader :vm_collection

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
    storage_object.store_type = 'KUBERNETES'
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
    status = object.status
    uid = object.metadata.uid
    name = object.metadata.name

    # Get the host name and the IP address:
    addresses = status.addresses
    hostname = addresses.detect { |address| address.type == 'Hostname' }.address
    ip = addresses.detect { |address| address.type == 'InternalIP' }.address

    # Get the node info:
    info = status.nodeInfo

    # Add the inventory object for the host:
    host_object = host_collection.find_or_build(uid)
    host_object.connection_state = 'connected'
    host_object.ems_cluster = cluster_collection.lazy_find(CLUSTER_ID)
    host_object.ems_ref = uid
    host_object.ems_ref_obj = uid
    host_object.hostname = hostname
    host_object.ipaddress = ip
    host_object.name = name
    host_object.type = ::Host.name
    host_object.uid_ems = uid
    host_object.vmm_product = ManageIQ::Providers::Kubevirt::Constants::PRODUCT
    host_object.vmm_vendor = ManageIQ::Providers::Kubevirt::Constants::VENDOR
    host_object.vmm_version = ManageIQ::Providers::Kubevirt::Constants::VERSION

    # Add the inventory object for the operating system details:
    os_object = os_collection.find_or_build(host_object)
    os_object.name = hostname
    os_object.product_name = info.osImage
    os_object.product_type = info.operatingSystem
    os_object.version = info.kernelVersion

    # Find the storage:
    storage_object = storage_collection.lazy_find(STORAGE_ID)

    # Add the inventory object for the host storage:
    host_storage_collection.find_or_build_by(
      :host    => host_object,
      :storage => storage_object,
    )
  end

  def process_offline_vms(objects)
    objects.each do |object|
      process_offline_vm(object)
    end
  end

  def process_offline_vm(object)
    # Get the basic information:
    uid = object.metadata.uid
    name = object.metadata.name
    domain = object.spec.template.spec.domain

    # Process the domain:
    vm_object = process_domain(domain, uid, name)

    # The power status is initially off, it will be set to on later if the live virtual machine exists:
    vm_object.raw_power_state = 'off'
  end

  def process_live_vms(objects)
    objects.each do |object|
      process_live_vm(object)
    end
  end

  def process_live_vm(object)
    # Get the basic information:
    uid = object.metadata.uid
    name = object.metadata.name
    domain = object.spec.domain

    # Get the identifier of the offline virtual machine from the owner reference:
    owner = find_owner(object, 'OfflineVirtualMachine')
    unless owner
      _log.info(
        "Live virtual machine with name '#{name}' and identifier '#{uid}' isn't owned by an offline virtual " \
        "machine; it will be ignored"
      )
      return
    end

    # Process the domain:
    vm_object = process_domain(domain, owner.uid, owner.name)

    # If the live virtual machine exists, then the it is powered on, regardless of the value of the `running` field of
    # the status:
    vm_object.raw_power_state = 'on'
  end

  def process_domain(domain, uid, name)
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

    # Create the inventory object for the hardware:
    hw_object = hw_collection.find_or_build(vm_object)
    hw_object.memory_mb = ManageIQ::Providers::Kubevirt::MemoryCalculator.convert(domain.memory, 'Mi')

    # Return the created inventory object:
    vm_object
  end

  def process_templates(objects)
    objects.each do |object|
      process_template(object)
    end
  end

  def process_template(object)
    # Get the basic information:
    uid = object.metadata.uid
    name = object.metadata.name
    domain = object.spec.template.spec.domain

    # Add the inventory object for the template:
    template_object = template_collection.find_or_build(uid)
    template_object.connection_state = 'connected'
    template_object.ems_ref = uid
    template_object.ems_ref_obj = uid
    template_object.name = name
    template_object.raw_power_state = 'never'
    template_object.template = true
    template_object.type = ::ManageIQ::Providers::Kubevirt::InfraManager::Template.name
    template_object.uid_ems = uid
    template_object.vendor = ManageIQ::Providers::Kubevirt::Constants::VENDOR

    # Add the inventory object for the hardware:
    hw_object = hw_collection.find_or_build(template_object)
    hw_object.memory_mb = ManageIQ::Providers::Kubevirt::MemoryCalculator.convert(domain.memory, 'Mi')
  end

  def find_owner(object, kind)
    owners = object.metadata.ownerReferences
    return nil unless owners
    owners.detect { |owner| owner.kind == kind }
  end
end
