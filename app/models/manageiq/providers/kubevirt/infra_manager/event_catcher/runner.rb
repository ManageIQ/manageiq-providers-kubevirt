class ManageIQ::Providers::Kubevirt::InfraManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
  include ManageIQ::Providers::Kubernetes::ContainerManager::EventCatcherMixin

  ENABLED_EVENTS = {
    'VirtualMachine'         => %w(Created Started Migrated SuccessfulCreate SuccessfulDelete ShuttingDown),
    'VirtualMachineInstance' => %w(Created Started Migrated SuccessfulCreate SuccessfulDelete ShuttingDown)
  }

  def event_monitor_handle
    @event_monitor_handle ||= ManageIQ::Providers::Kubevirt::InfraManager::KubernetesEventMonitor.new(@ems)
  end

  def queue_event(event)
    event_hash = @ems.class::EventParser.event_to_hash(event, @cfg[:ems_id], @ems.emstype.upcase)

    if event_hash[:timestamp].nil?
      _log.info("#{log_prefix} Skipping invalid event [#{event_hash[:event_type]}]")
      return
    end

    _log.info("#{log_prefix} Queuing event [#{event_hash}]")

    EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
  end

  def filtered?(event)
    kind = event.object.involvedObject.kind
    reason = event.object.reason
    event_type = "#{kind.upcase}_#{reason.upcase}"

    supported_reasons = ENABLED_EVENTS[kind] || []
    supported_reasons.exclude?(reason) || filtered_events.include?(event_type)
  end

  private

  def worker_cmdline
    ManageIQ::Providers::Kubevirt::Engine.root.join("workers/manageiq/providers/kubevirt/infra_manager/event_catcher/worker").to_s
  end
end
