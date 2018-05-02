describe 'VM::Operations' do
  let(:default_endpoint) do
    FactoryGirl.create(:endpoint,
                       :role       => 'default',
                       :hostname   => 'host.example.com',
                       :port       => 6443,
                       :verify_ssl => 0)
  end

  let(:default_authentication) { FactoryGirl.create(:authentication, :authtype => 'bearer') }

  let(:kubevirt_authentication) do
    FactoryGirl.create(
      :authentication,
      :authtype => 'kubevirt',
      :auth_key => '_'
    )
  end

  let(:kubevirt_endpoint) do
    EvmSpecHelper.local_miq_server(:zone => Zone.seed)
    FactoryGirl.build(
      :endpoint,
      :role       => 'kubevirt',
      :hostname   => 'host.example.com',
      :port       => 6443,
      :verify_ssl => false
    )
  end

  let(:container_manager) do
    FactoryGirl.create(
      :ems_kubernetes,
      :endpoints       => [
        default_endpoint,
        kubevirt_endpoint,
      ],
      :authentications => [
        default_authentication,
        kubevirt_authentication,
      ],
    )
  end

  context '#raw_destroy' do
    let(:infra_manager) { container_manager.infra_manager }
    let(:vm) { FactoryGirl.create(:vm_kubevirt, :ext_management_system => infra_manager) }
    let(:connection) { double("connection") }
    let(:live_vm_metadata) { double("live_vm_metadata", :namespace => "default") }
    let(:offline_vm_metadata) { double("offline_vm_metadata", :namespace => "default") }
    let(:live_vm) { double("live_vm", :metadata => live_vm_metadata) }
    let(:offline_vm) { double("offline_vm", :metadata => offline_vm_metadata) }

    context 'running vm' do
      it 'removes an running vm from kubevirt provider' do
        allow(connection).to receive(:live_vm).and_return(live_vm)
        allow(connection).to receive(:offline_vm).and_return(offline_vm)
        allow(infra_manager).to receive(:with_provider_connection).and_yield(connection)

        expect(connection).to receive(:delete_live_vm)

        vm.raw_destroy
      end
    end

    context 'stopped vm' do
      it 'removes a stopped vm from kubevirt provider' do
        require 'kubeclient'
        error = KubeException.new(404, "entity not found", "")
        allow(connection).to receive(:live_vm).and_raise(error)
        allow(connection).to receive(:offline_vm).and_return(offline_vm)
        allow(infra_manager).to receive(:with_provider_connection).and_yield(connection)

        expect(connection).not_to receive(:delete_live_vm)

        vm.raw_destroy
      end
    end
  end
end
