class ManageIQ::Providers::Kubevirt::InfraManager::KubernetesEventMonitor < ManageIQ::Providers::Kubernetes::ContainerManager::KubernetesEventMonitor
  def inventory
    # :service is required to handle also the case where @ems is Openshift
    @inventory ||= @ems.parent_manager.connect(:service => ManageIQ::Providers::Kubernetes::ContainerManager.ems_type)
  end
end
