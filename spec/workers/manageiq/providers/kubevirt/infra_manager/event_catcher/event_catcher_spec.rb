require_relative '../../../../../../../workers/manageiq/providers/kubevirt/infra_manager/event_catcher/event_parser'
require_relative '../../../../../../../workers/manageiq/providers/kubevirt/infra_manager/event_catcher/event_catcher'

RSpec.describe ManageIQ::Providers::Kubevirt::Workers::InfraManager::EventCatcher do
  let(:ems)            { {'id' => 1, 'type' => 'ManageIQ::Providers::Kubevirt::InfraManager', 'ems_type' => 'kubevirt'} }
  let(:endpoint)       { {'hostname' => 'localhost'} }
  let(:authentication) { {'auth_key' => 'test-token'} }
  let(:settings)       { {'ems' => {'ems_kubevirt' => {'blacklisted_event_names' => []}}} }
  let(:logger)         { instance_double('Logger', :debug => nil, :info => nil, :warn => nil, :error => nil) }

  subject(:catcher) { described_class.new(ems, endpoint, authentication, settings, {}, logger) }

  def event(kind, reason)
    RecursiveOpenStruct.new(:object => {
                              :lastTimestamp  => '2024-11-19T16:29:11Z',
                              :involvedObject => {:kind => kind, :name => 'name', :uid => 'uid'},
                              :reason         => reason,
                              :metadata       => {:uid => 'event-uid'}
                            })
  end

  def event_data(kind, reason)
    ManageIQ::Providers::Kubevirt::Workers::InfraManager::EventParser.extract_event_data(event(kind, reason))
  end

  describe '#filtered?' do
    context 'VM/VMI kinds' do
      ManageIQ::Providers::Kubevirt::Workers::InfraManager::EventParser::ENABLED_EVENTS.each do |kind, reasons|
        reasons.each do |reason|
          it "allows #{kind}/#{reason}" do
            expect(catcher.send(:filtered?, event_data(kind, reason))).to be(false)
          end
        end

        it "filters #{kind} with an unsupported reason" do
          expect(catcher.send(:filtered?, event_data(kind, 'UnknownReason'))).to be(true)
        end
      end
    end

    context 'non-VM kinds' do
      %w[Node Pod Deployment ReplicaSet].each do |kind|
        it "filters #{kind} events entirely" do
          expect(catcher.send(:filtered?, event_data(kind, 'SomeReason'))).to be(true)
        end
      end
    end

    context 'with blacklisted events' do
      let(:settings) { {'ems' => {'ems_kubevirt' => {'blacklisted_event_names' => %w[VIRTUALMACHINE_STARTED]}}} }

      it 'filters VM events whose event_type is blacklisted' do
        expect(catcher.send(:filtered?, event_data('VirtualMachine', 'Started'))).to be(true)
      end
    end

    context 'with a subclass overriding event_parser' do
      let(:custom_event_parser) do
        Class.new do
          const_set(:ENABLED_EVENTS, {'CustomKind' => %w[CustomReason]}.freeze)
        end
      end

      let(:subclass) do
        parser = custom_event_parser
        Class.new(described_class) do
          define_method(:event_parser) { parser }
        end
      end

      subject(:custom_catcher) { subclass.new(ems, endpoint, authentication, settings, {}, logger) }

      it 'respects ENABLED_EVENTS from the subclassed event_parser' do
        expect(custom_catcher.send(:filtered?, {:kind => 'CustomKind', :reason => 'CustomReason', :event_type => 'CUSTOM_KIND_CUSTOM_REASON'})).to be(false)
        expect(custom_catcher.send(:filtered?, {:kind => 'VirtualMachine', :reason => 'Started', :event_type => 'VIRTUALMACHINE_STARTED'})).to be(true)
      end
    end
  end

  describe '#log_prefix' do
    it 'includes the KubeVirt EventCatcher class name' do
      expect(catcher.send(:log_prefix)).to include('Kubevirt')
    end
  end

  describe '#event_parser' do
    it 'uses the Kubevirt EventParser' do
      expect(catcher.send(:event_parser)).to eq(ManageIQ::Providers::Kubevirt::Workers::InfraManager::EventParser)
    end
  end
end
