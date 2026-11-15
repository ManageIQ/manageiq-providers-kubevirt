class ManageIQ::Providers::Kubevirt::InfraManager::MetricsCapture < ManageIQ::Providers::InfraManager::MetricsCapture
  include ManageIQ::Providers::Kubernetes::ContainerManager::MetricsCaptureMixin

  def capture_ems_targets(options = {})
    begin
      verify_metrics_connection!(ems)
    rescue TargetValidationError, TargetValidationWarning => e
      _log.send(e.log_severity, e.message)
      return []
    end

    load_infra_targets_data(ems, options)
    all_hosts = capture_host_targets(ems)
    enabled_hosts = only_enabled(all_hosts)

    capture_vm_targets(ems, enabled_hosts)
  end

  def prometheus_capture_context(target, start_time, end_time)
    ManageIQ::Providers::Kubevirt::InfraManager::MetricsCapture::PrometheusCaptureContext.new(target, start_time, end_time, INTERVAL)
  end
end
