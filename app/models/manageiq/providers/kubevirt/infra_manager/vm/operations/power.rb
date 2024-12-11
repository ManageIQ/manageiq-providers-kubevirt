module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations::Power
  def raw_start
    ext_management_system.with_provider_connection(:namespace => location) do |connection|
      # Retrieve the details of the virtual machine:
      vm = connection.vm(name)
      vm.start
    end
  end

  def raw_stop
    ext_management_system.with_provider_connection(:namespace => location) do |connection|
      # Retrieve the details of the virtual machine:
      vm = connection.vm(name)
      vm.stop
    end
  end

  def raw_create_snapshot(name, desc = nil, memory = false)
    ext_management_system.with_provider_connection(:namespace => location) do |connection|
      # Define the payload for the snapshot creation request
      payload = {
        "apiVersion" => "snapshot.kubevirt.io/v1alpha1",
        "kind" => "VirtualMachineSnapshot",
        "metadata" => {
          "name" => name,
          "namespace" => 'default'
        },
        "spec" => {
          "source" => {
            "apiGroup" => "kubevirt.io",
            "kind" => "VirtualMachine",
            "name" => 'centos-stream9-cyan-silkworm-83'
          }
        }
      }

      # Log debugging information for validation
      log_prefix = "vm=[#{(name)}]"
      _log.info("#{log_prefix}: Attempting to create snapshot.")
      _log.info("#{log_prefix}: Payload: #{payload.to_json}")
      _log.info("#{log_prefix}: Target URL: /apis/snapshot.kubevirt.io/v1alpha1/namespaces/#{location}/virtualmachinesnapshots")

      # Perform the snapshot creation request
      begin
        response = connection.post(
          "/apis/snapshot.kubevirt.io/v1alpha1/namespaces/#{location}/virtualmachinesnapshots",
          payload.to_json,
          'Content-Type' => 'application/json'
        )

        # Debugging response
        _log.info("#{log_prefix}: Snapshot creation response: #{response.inspect}")

        # Check for HTTP errors in the response
        if response.status >= 400
          raise MiqException::MiqVmSnapshotError, "#{log_prefix}: HTTP Error #{response.status}: #{response.body}"
        end
      rescue StandardError => e
        _log.error("#{log_prefix}: Error during snapshot creation: #{e.message}")
        _log.debug("#{log_prefix}: Backtrace: #{e.backtrace.join("\n")}")
        raise MiqException::MiqVmSnapshotError, "#{log_prefix}: Failed to create snapshot: #{e.message}"
      end

      _log.info("#{log_prefix}: Snapshot '#{name}' successfully created.")
    end
  end
end
