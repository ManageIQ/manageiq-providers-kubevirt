require_relative '../../../workers/manageiq/providers/kubevirt/infra_manager/event_catcher/event_parser'

RSpec.describe ManageIQ::Providers::Kubevirt::Workers::InfraManager::EventParser do
  let(:fixture_dir) { File.expand_path('data', __dir__) }

  def load_event(name)
    RecursiveOpenStruct.new(YAML.unsafe_load(File.read(File.join(fixture_dir, name))), :recurse_over_arrays => true)
  end

  def parse(name, ems_id = 42)
    described_class.event_to_hash_from_data(described_class.extract_event_data(load_event(name)), ems_id)
  end

  describe '.extract_event_data' do
    it 'sets vm_name and vm_ems_ref for VirtualMachine events' do
      data = described_class.extract_event_data(load_event('vm_started.yml'))
      expect(data[:vm_name]).to eq('test-vm')
      expect(data[:vm_ems_ref]).to eq('123-456-789')
    end

    it 'sets vm_name and vm_ems_ref for VirtualMachineInstance events' do
      data = described_class.extract_event_data(load_event('vmi_shutting_down.yml'))
      expect(data[:vm_name]).to eq('test-vm')
      expect(data[:vm_ems_ref]).to eq('123-456-789')
    end

    it 'returns empty hash when involvedObject is nil' do
      raw = RecursiveOpenStruct.new(:object => {:involvedObject => nil, :metadata => {:uid => 'x'}})
      expect(described_class.extract_event_data(raw)).to eq({})
    end
  end

  describe '.event_to_hash_from_data' do
    it 'sets source to KUBEVIRT for VM events' do
      expect(parse('vm_started.yml')[:source]).to eq('KUBEVIRT')
    end

    it 'sets source to KUBEVIRT for VMI events' do
      expect(parse('vmi_shutting_down.yml')[:source]).to eq('KUBEVIRT')
    end

    it 'includes vm_name and vm_ems_ref for VirtualMachine events' do
      hash = parse('vm_started.yml')
      expect(hash).to include(
        :event_type => 'VIRTUALMACHINE_STARTED',
        :vm_name    => 'test-vm',
        :vm_ems_ref => '123-456-789',
        :ems_id     => 42,
        :ems_ref    => '987-654-321',
        :timestamp  => '2024-11-19T16:29:11Z'
      )
    end

    it 'includes vm_name and vm_ems_ref for VirtualMachineInstance events' do
      hash = parse('vmi_shutting_down.yml')
      expect(hash).to include(
        :event_type => 'VIRTUALMACHINEINSTANCE_SHUTTINGDOWN',
        :vm_name    => 'test-vm',
        :vm_ems_ref => '123-456-789',
        :ems_ref    => '987-654-322'
      )
    end

    it 'does not include vm_name or vm_ems_ref for non-VM kinds' do
      raw = RecursiveOpenStruct.new(
        :object => {
          :metadata       => {:uid => 'event-1'},
          :involvedObject => {:kind => 'Node', :name => 'node-1', :uid => 'node-uid'},
          :reason         => 'Rebooted',
          :lastTimestamp  => '2024-01-01T00:00:00Z'
        }
      )
      data = described_class.extract_event_data(raw)
      hash = described_class.event_to_hash_from_data(data, 1)
      expect(hash).not_to have_key(:vm_name)
      expect(hash).not_to have_key(:vm_ems_ref)
    end
  end
end
