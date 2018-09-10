class ManageIQ::Providers::Kubevirt::Inventory < ManageIQ::Providers::Inventory
  require_nested :Collector
  require_nested :Parser
  require_nested :Persister

  def self.persister_class_for(_ems, _target)
    ManageIQ::Providers::Kubevirt::Inventory::Persister
  end

  def self.collector_class_for(_ems, _target)
    ManageIQ::Providers::Kubevirt::Inventory::Collector
  end

  def self.parser_class_for(_ems, target)
    parser_type = if target_is_vm?(target)
                    "PartialTargetRefresh"
                  else
                    "FullRefresh"
                  end
    "ManageIQ::Providers::Kubevirt::Inventory::Parser::#{parser_type}".safe_constantize
  end

  def self.build(ems, target)
    collector_class = collector_class_for(ems, target)

    collector = if target_is_vm?(target)
                  collector_class.new(ems, target)
                else
                  collector_class.new(ems, ems)
                end

    persister = persister_class_for(ems, target).new(ems, target)
    new(
      persister,
      collector,
      parser_classes_for(ems, target).map(&:new)
    )
  end

  def self.target_is_vm?(target)
    target.kind_of?(ManageIQ::Providers::Kubevirt::InfraManager::Vm)
  end
end
