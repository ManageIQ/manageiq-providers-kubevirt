class ManageIQ::Providers::Kubevirt::Inventory::Collector::WatchNotice < ManageIQ::Providers::Kubevirt::Inventory::Collector::InfraManager
  attr_accessor :nodes
  attr_accessor :vms
  attr_accessor :vm_instances
  attr_accessor :templates
end
