class ManageIQ::Providers::Kubevirt::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  attr_reader :nodes
  attr_reader :instance_types
  attr_reader :vms
  attr_reader :vm_instances
  attr_reader :templates
end
