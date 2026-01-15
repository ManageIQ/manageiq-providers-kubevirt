class ManageIQ::Providers::Kubevirt::InfraManager::MetricsCapture::PrometheusCaptureContext < ManageIQ::Providers::Kubernetes::ContainerManager::MetricsCapture::PrometheusCaptureContext
  def initialize(target, start_time, end_time, interval)
    @target = target
    @starts = start_time.to_i.in_milliseconds
    @ends = end_time.to_i.in_milliseconds if end_time
    @interval = interval.to_i
    @tenant = target.try(:container_project).try(:name) || '_system'
    @ext_management_system = @target.ext_management_system
    @ts_values = Hash.new { |h, k| h[k] = {} }
    @metrics = []

    @vm_hardware = @target.hardware
    @vm_cores = @vm_hardware.try(:cpu_total_cores)
    @vm_memory = @vm_hardware.try(:memory_mb)

    validate_target
  end

  def prometheus_endpoint
    @ext_management_system.parent_manager.connection_configurations.prometheus.endpoint
  end

  def prometheus_credentials
    {:token => @ext_management_system.parent_manager.authentication_token("prometheus")}
  end

  def prometheus_options
    {
      :http_proxy_uri => VMDB::Util.http_proxy_uri.to_s.presence,
      :verify_ssl     => @ext_management_system.parent_manager.verify_ssl_mode(prometheus_endpoint),
      :ssl_cert_store => @ext_management_system.parent_manager.ssl_cert_store(prometheus_endpoint),
      :open_timeout   => 5,
      :timeout        => 30
    }
  end

  def collect_metrics
    labels = labels_to_s(:name => @target.name)

    collect_metrics_for_labels(labels)
  end

  def collect_metrics_for_labels(labels)
    # prometheus field is in core usage per sec
    # miq field is in pct of vm cpu
    #
    #   rate is the "usage per sec" readings avg over last 5m

    cpu_resid = "sum(rate(kubevirt_vmi_cpu_user_usage_seconds_total{#{labels}}[#{AVG_OVER}]))"
    fetch_counters_data(cpu_resid, 'cpu_usage_rate_average', @vm_cores / 100.0)

    # prometheus field is in bytes, @vm_memory is in MiB
    # miq field is in pct of vm memory
    mem_resid = "sum(kubevirt_vmi_memory_used_bytes{#{labels}})"
    fetch_counters_data(mem_resid, 'mem_usage_absolute_average', @vm_memory * 1.megabyte.to_f / 100.0)

    # prometheus field is in bytes
    # miq field is on KiB ( / 1024 )
    if @metrics.include?('net_usage_rate_average')
      net_resid = "sum(rate(kubevirt_vmi_network_receive_bytes_total{#{labels}\"}[#{AVG_OVER}])) + " \
                  "sum(rate(kubevirt_vmi_network_transmit_bytes_total{#{labels}\"}[#{AVG_OVER}]))"
      fetch_counters_data(net_resid, 'net_usage_rate_average', 1024.0)
    end

    @ts_values
  end

  def labels_to_s(labels)
    labels.compact.sort.map { |k, v| "#{k}=\"#{v}\"" }.join(',')
  end

  def validate_target
    raise TargetValidationError, "ems not defined" unless @ext_management_system
    raise TargetValidationWarning, "no associated hardware" unless @vm_hardware

    raise TargetValidationError, "cores not defined" unless @vm_cores.to_i > 0
    raise TargetValidationError, "memory not defined" unless @vm_memory.to_i > 0
  end
end
