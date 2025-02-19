module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Power
  def raw_start
    with_provider_connection do |connection|
      start_options = Kubevirt::V1StartOptions.new
      connection.v1_start(name, location, start_options)
    end
  end

  def raw_stop
    with_provider_connection do |connection|
      connection.v1_stop(name, location)
    end
  end
end
