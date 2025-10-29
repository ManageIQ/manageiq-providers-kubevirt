class ManageIQ::Providers::Kubevirt::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  attr_accessor :nodes
  attr_accessor :instance_types
  attr_accessor :vms
  attr_accessor :vm_instances
  attr_accessor :templates
end
