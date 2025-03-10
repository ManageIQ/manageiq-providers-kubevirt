class ManageIQ::Providers::Kubevirt::InfraManager::Vm < ManageIQ::Providers::InfraManager::Vm
  include Operations
  include RemoteConsole
  POWER_STATES = {
    'Running'    => 'on',
    'Pending'    => 'powering_up',
    'Scheduling' => 'powering_up',
    'Scheduled'  => 'off',
    'Succeeded'  => 'off',
    'Failed'     => 'off',
    'Unknown'    => 'terminated'
  }.freeze

  supports :capture
  supports :snapshots

  supports :reboot_guest do
    _('The VM is not powered on') unless current_state == 'on'
  end
  supports :reset
  def self.calculate_power_state(raw)
    POWER_STATES[raw] || super
  end

  #
  # UI Button Validation Methods
  #

  # We need this method to workaround VmOrTemplate.validate_task
  def has_required_host?
    true
  end

  def self.display_name(number = 1)
    n_('Virtual Machine (Kubevirt)', 'Virtual Machines (Kubevirt)', number)
  end

  def params_for_create_snapshot
    {
      :fields => [
        {
          :component  => 'text-field',
          :name       => 'name',
          :id         => 'name',
          :label      => _('Name'),
          :isRequired => true,
          :validate   => [{:type => 'required'}],
        },
        {
          :component  => 'textarea',
          :name       => 'description',
          :id         => 'description',
          :label      => _('Description'),
          :isRequired => true,
          :validate   => [{:type => 'required'}],
        },
      ],
    }
  end
end
