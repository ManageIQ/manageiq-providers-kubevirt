module ManageIQ::Providers::Kubevirt::InfraManager::Vm::RemoteConsole
  def console_supported?(type)
    %w(VNC).include?(type.upcase)
  end
end
