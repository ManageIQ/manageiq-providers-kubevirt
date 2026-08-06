module ManageIQ::Providers::Kubevirt::InfraManager::Vm::RemoteConsole
  def console_supported?(type)
    %w[VNC HTML5].include?(type.upcase)
  end

  def validate_remote_console_acquire_ticket(protocol, _options = {})
    if ext_management_system.nil?
      raise(MiqException::RemoteConsoleNotSupportedError,
            "#{protocol} remote console requires the vm to be registered with a management system.")
    end

    unless state == "on"
      raise(MiqException::RemoteConsoleNotSupportedError,
            "#{protocol} remote console requires the vm to be running.")
    end
  end

  def remote_console_acquire_ticket(userid, originating_server, protocol)
    send("remote_console_#{protocol.to_s.downcase}_acquire_ticket", userid, originating_server)
  end

  def remote_console_acquire_ticket_queue(protocol, userid)
    task_opts = {
      :action => "acquiring VM #{name} #{protocol.to_s.upcase} remote console ticket for user #{userid}",
      :userid => userid
    }

    queue_opts = {
      :class_name  => self.class.name,
      :instance_id => id,
      :method_name => "remote_console_acquire_ticket",
      :queue_name  => ext_management_system.queue_name_for_ems_operations,
      :priority    => MiqQueue::HIGH_PRIORITY,
      :role        => "ems_operations",
      :zone        => my_zone,
      :args        => [userid, MiqServer.my_server.id, protocol]
    }

    MiqTask.generic_action_with_callback(task_opts, queue_opts)
  end

  def remote_console_vnc_acquire_ticket(userid, originating_server = nil)
    validate_remote_console_acquire_ticket("vnc")

    SystemConsole.force_vm_invalid_token(id)

    api_uri = ext_management_system.parent_manager.api_endpoint

    console_args = {
      :user       => User.find_by(:userid => userid),
      :vm_id      => id,
      :ssl        => true,
      :protocol   => "kubevirt_vnc",
      :secret     => SecureRandom.hex,
      :url_secret => SecureRandom.hex,
      :url        => build_kubevirt_vnc_url(api_uri)
    }

    SystemConsole.launch_proxy_if_not_local(
      console_args,
      originating_server,
      api_uri.host,
      api_uri.port
    )
  end

  def remote_console_html5_acquire_ticket(userid, originating_server = nil)
    remote_console_vnc_acquire_ticket(userid, originating_server)
  end

  private

  def build_kubevirt_vnc_url(api_uri)
    URI::Generic.build(
      :scheme => "wss",
      :host   => api_uri.host,
      :port   => api_uri.port,
      :path   => kubevirt_vnc_path
    ).to_s
  end

  def kubevirt_vnc_path
    "/apis/subresources.kubevirt.io/v1/namespaces/#{kubevirt_namespace}/virtualmachineinstances/#{name}/vnc"
  end

  def kubevirt_namespace
    location.presence.tap do |ns|
      if ns.blank? || ns == "unknown"
        raise MiqException::RemoteConsoleNotSupportedError,
              "Unable to determine the namespace for VM #{name}. A provider refresh may be required."
      end
    end
  end
end
