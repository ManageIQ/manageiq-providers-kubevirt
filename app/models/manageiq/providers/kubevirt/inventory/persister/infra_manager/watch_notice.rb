class ManageIQ::Providers::Kubevirt::Inventory::Persister::InfraManager::WatchNotice < ManageIQ::Providers::Kubevirt::Inventory::Persister::InfraManager
  def targeted?
    true
  end

  def strategy
    :local_db_find_missing_references
  end
end
