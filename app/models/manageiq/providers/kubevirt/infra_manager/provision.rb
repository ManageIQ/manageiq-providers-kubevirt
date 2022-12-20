class ManageIQ::Providers::Kubevirt::InfraManager::Provision < MiqProvision
  include_concern 'Cloning'
  include_concern 'StateMachine'

  #
  # The ManageIQ core calls this method during the provision workflow to get the name of the object that is being
  # provisioned, only to include it in the generated log messages.
  #
  def destination_type
    'VM'
  end
end
