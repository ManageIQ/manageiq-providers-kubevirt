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
# This class is responsible for parsing the inventory for the provider object.
#
class ManageIQ::Providers::KubeVirt::Inventory::Parser::InfraManager < ManagerRefresh::Inventory::Parser
  def parse
    parse_nodes
    parse_virtual_machine_templates
    parse_virtual_machines
  end

  private

  #
  # The details of the vendor:
  #
  KUBEVIRT_VENDOR = 'kubevirt'.freeze
  KUBEVIRT_PRODUCT = 'KubeVirt'.freeze
  KUBEVIRT_VERSION = '0.0.3'.freeze

  def parse_nodes
    collector.nodes.each do |node|
      parse_node(node)
    end
  end

  def parse_node(node)
    # Get the basic information:
    status = node.status
    uid = node.metadata.uid
    name = node.metadata.name

    # Get the host name and the IP address:
    addresses = status.addresses
    hostname = addresses.detect { |a| a.type == 'Hostname' }.address
    ip = addresses.detect { |a| a.type == 'InternalIP' }.address

    # Get the node info:
    info = status.nodeInfo

    # Create the persister for the node:
    host_persister = persister.hosts.find_or_build(uid).assign_attributes(
      connection_state: 'connected',
      ems_ref: uid,
      ems_ref_obj: uid,
      hostname: hostname,
      ipaddress: ip,
      name: name,
      type: ::Host.name,
      uid_ems: uid,
      vmm_product: KUBEVIRT_PRODUCT,
      vmm_vendor: KUBEVIRT_VENDOR,
      vmm_version: KUBEVIRT_VERSION,
    )

    # Create the persister for the node operating system details:
    os_persister = persister.host_operating_systems.find_or_build(host_persister).assign_attributes(
      name: hostname,
      product_name: info.osImage,
      product_type: info.operatingSystem,
      version: info.kernelVersion,
    )
  end

  def parse_virtual_machine_templates
    collector.virtual_machine_templates.each do |template|
      parse_virtual_machine_template(template)
    end
  end

  def parse_virtual_machine_template(template)
    # Get the basic information:
    uid = template.metadata.uid
    name = template.metadata.name
    domain = template.spec.domain

    # Create the persister for the virtual machine:
    template_persister = persister.miq_templates.find_or_build(uid).assign_attributes(
      connection_state: 'connected',
      ems_ref: uid,
      ems_ref_obj: uid,
      name: name,
      raw_power_state: 'never',
      template: true,
      type: ::ManageIQ::Providers::KubeVirt::InfraManager::Template.name,
      uid_ems: uid,
      vendor: KUBEVIRT_VENDOR,
    )

    # Create the persister for the hardware information:
    hw_persister = persister.hardwares.find_or_build(template_persister).assign_attributes(
      memory_mb: convert_memory(domain.memory.value, domain.memory.unit, 'MiB')
    )
  end

  def parse_virtual_machines
    # Find the stored and live virtual machines:
    all_stored = collector.stored_virtual_machines
    all_live = collector.virtual_machines

    # For each stored virtual machine we need to check if there is a corresponding live virtual machine. Currently
    # we do this matching using the `metadata.name` attribute, but that is weak, it would be better if live virtual
    # machines had an attribute or a label indicating explicitly from what stored virtual machine they have been
    # created.
    all_stored.each do |stored|
      live = all_live.detect { |live| live.metadata.name == stored.metadata.name }
      parse_virtual_machine(stored, live)
    end

    # Some live virtual machines may not have a stored counterpart. Currently we are just silently ignoring them,
    # but we could maybe automatically create the stored counterpart.
  end

  def parse_virtual_machine(stored, live)
    # Get the basic information:
    uid = stored.metadata.uid
    name = stored.metadata.name
    domain = stored.spec.domain

    # Calculate the state of the virtual machine:
    if live
      state = live.status.phase
    else
      state = 'off'
    end

    # Create the persister for the virtual machine:
    vm_persister = persister.vms.find_or_build(uid).assign_attributes(
      connection_state: 'connected',
      ems_ref: uid,
      ems_ref_obj: uid,
      name: name,
      raw_power_state: state,
      template: false,
      type: ::ManageIQ::Providers::KubeVirt::InfraManager::Vm.name,
      uid_ems: uid,
      vendor: KUBEVIRT_VENDOR,
    )

    # Create the persister for the hardware information:
    hw_persister = persister.hardwares.find_or_build(vm_persister).assign_attributes(
      memory_mb: convert_memory(domain.memory.value, domain.memory.unit, 'MiB')
    )
  end

  MEMORY_UNIT_MULTIPLIERS = {
    'B' => 1,

    'KB' => 10**3,
    'MB' => 10**6,
    'GB' => 10**9,
    'TB' => 10**12,
    'PB' => 10**15,
    'EB' => 10**18,
    'ZB' => 10**21,
    'YB' => 10**24,

    'KiB' => 2**10,
    'MiB' => 2**20,
    'GiB' => 2**30,
    'TiB' => 2**40,
    'PiB' => 2**50,
    'EiB' => 2**60,
    'ZiB' => 2**70,
    'YiB' => 2**80
  }.freeze

  def convert_memory(value, from_unit, to_unit)
    from_unit ||= 'B'
    from_multiplier = MEMORY_UNIT_MULTIPLIERS[from_unit]
    to_unit ||= 'B'
    to_multiplier = MEMORY_UNIT_MULTIPLIERS[to_unit]
    value * from_multiplier / to_multiplier
  end
end
