describe ManageIQ::Providers::Kubevirt::InfraManager::EventParser do
  let(:vm_started) do
    {
      "object" => {
        "involvedObject" => {
          "kind"      => "VirtualMachine",
          "namespace" => "test-namespace",
          "name"      => "test-vm",
          "uid"       => "123-456-789"
        },
        "metadata"       => {
          "uid" => "987-654-321"
        },
        "reason"         => "Started",
        "message"        => "VirtualMachine started",
        "lastTimestamp"  => "2024-11-19T16:29:11Z"
      }
    }
  end

  context 'event_to_hash' do
    it 'parses vm started into event' do
      event = RecursiveOpenStruct.new(vm_started, :recurse_over_arrays => true)
      hash = described_class.event_to_hash(event, nil, "KUBEVIRT")

      expect(hash).to include(
        :event_type          => 'VIRTUALMACHINE_STARTED',
        :source              => 'KUBEVIRT',
        :timestamp           => "2024-11-19T16:29:11Z",
        :message             => "VirtualMachine started",
        :container_namespace => "test-namespace",
        :full_data           => event.to_h,
        :ems_id              => nil,
        :ems_ref             => "987-654-321",
        :vm_name             => "test-vm",
        :vm_ems_ref          => "123-456-789"
      )
    end
  end
end
