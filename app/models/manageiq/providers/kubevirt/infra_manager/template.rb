class ManageIQ::Providers::Kubevirt::InfraManager::Template < ManageIQ::Providers::InfraManager::Template
  supports :provisioning do
    if ext_management_system
      unsupported_reason_add(:provisioning, ext_management_system.unsupported_reason(:provisioning)) unless ext_management_system.supports?(:provisioning)
    else
      unsupported_reason_add(:provisioning, _('not connected to ems'))
    end
  end

  def self.display_name(number = 1)
    n_('Template (Kubevirt)', 'Templates (Kubevirt)', number)
  end
end
