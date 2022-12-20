module ManageIQ::Providers::Kubevirt::InfraManager::Provision::StateMachine
  def create_destination
    signal :determine_placement
  end

  def determine_placement
    signal :prepare_provision
  end

  def start_clone_task
    update_and_notify_parent(:message => "Starting clone of #{clone_direction}")

    log_clone_options(phase_context[:clone_options])
    start_clone(phase_context[:clone_options])
    phase_context.delete(:clone_options)

    signal :poll_destination_in_vmdb
  end

  def customize_destination
    signal :post_provision
  end
end
