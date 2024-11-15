class ManageIQ::Providers::Kubevirt::InfraManager::EventParser
  def self.event_to_hash(event, ems_id = nil, source)
    _log.debug("ems_id: [#{ems_id}] event: [#{event.inspect}]")

    kind = event.object.involvedObject.kind
    event_hash = {
      :event_type          => "#{kind.upcase}_#{event.object.reason.upcase}",
      :source              => source,
      :timestamp           => event.object.lastTimestamp,
      :message             => event.object.message,
      :container_namespace => event.object.involvedObject.namespace,
      :full_data           => event.to_h,
      :ems_id              => ems_id,
      :ems_ref             => event.object.metadata.uid,
    }

    if ["VirtualMachine", "VirtualMachineInstance"].include?(kind)
      event_hash[:vm_name] = event.object.involvedObject.name
      event_hash[:vm_ems_ref] = event.object.involvedObject.uid
    end

    event_hash
  end
end
