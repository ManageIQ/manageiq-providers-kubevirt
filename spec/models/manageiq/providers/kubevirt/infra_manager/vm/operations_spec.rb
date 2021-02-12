describe 'VM::Operations' do
  let(:default_endpoint) do
    FactoryBot.create(:endpoint,
                       :role       => 'default',
                       :hostname   => 'host.example.com',
                       :port       => 6443,
                       :verify_ssl => 0)
  end

  let(:default_authentication) { FactoryBot.create(:authentication, :authtype => 'bearer') }

  let(:kubevirt_authentication) do
    FactoryBot.create(
      :authentication,
      :authtype => 'kubevirt',
      :auth_key => '_'
    )
  end

  let(:kubevirt_endpoint) do
    EvmSpecHelper.local_miq_server(:zone => Zone.seed)
    FactoryBot.build(
      :endpoint,
      :role       => 'kubevirt',
      :hostname   => 'host.example.com',
      :port       => 6443,
      :verify_ssl => false
    )
  end

  let(:container_manager) do
    FactoryBot.create(
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
    let(:vm) { FactoryBot.create(:vm_kubevirt, :ext_management_system => infra_manager) }
    let(:connection) { double("connection") }
    let(:vm_instance_metadata) { double("vm_instance_metadata", :namespace => "default") }
    let(:vm_instance) { double("vm_instance", :metadata => vm_instance_metadata) }
    let(:vm_metadata) { double("vm_metadata", :namespace => "default") }
    let(:provider_vm) { double("provider_vm", :metadata => vm_metadata) }

    it "supports?(:terminate)" do
      expect(vm.supports?(:terminate)).to be_truthy
    end

    context 'running vm' do
      it 'removes an running vm from kubevirt provider' do
        allow(connection).to receive(:vm_instance).and_return(vm_instance)
        allow(connection).to receive(:vm).and_return(provider_vm)
        allow(infra_manager).to receive(:with_provider_connection).and_yield(connection)

        expect(connection).to receive(:delete_vm_instance)

        vm.raw_destroy
      end
    end

    context 'stopped vm' do
      it 'removes a stopped vm from kubevirt provider' do
        require 'fog/kubevirt'
        error = Fog::Kubevirt::Errors::ClientError.new
        allow(connection).to receive(:vm_instance).and_raise(error)
        allow(connection).to receive(:vm).and_return(provider_vm)
        allow(infra_manager).to receive(:with_provider_connection).and_yield(connection)

        expect(connection).not_to receive(:delete_vm_instance)

        vm.raw_destroy
      end
    end
  end
end
