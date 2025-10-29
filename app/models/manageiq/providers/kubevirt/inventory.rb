class ManageIQ::Providers::Kubevirt::Inventory < ManageIQ::Providers::Inventory
  def self.persister_class_for(_ems, _target)
    ManageIQ::Providers::Kubevirt::Inventory::Persister
  end

  def self.collector_class_for(_ems, _target)
    ManageIQ::Providers::Kubevirt::Inventory::Collector::FullRefresh
  end

  def self.parser_class_for(_ems, _target)
    ManageIQ::Providers::Kubevirt::Inventory::Parser::FullRefresh
  end

  def self.build(ems, target)
    collector = collector_class_for(ems, target).new(ems, target)
    persister = persister_class_for(ems, target).new(ems, target)
    new(
      persister,
      collector,
      parser_classes_for(ems, target).map(&:new)
    )
  end
end
