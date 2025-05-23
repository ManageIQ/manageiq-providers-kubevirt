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
    let(:connection) { double("Kubevirt::DefaultApi") }
    let(:vm_instance_metadata) { double("vm_instance_metadata", :namespace => "default") }
    let(:vm_instance) { double("vm_instance", :metadata => vm_instance_metadata) }
    let(:vm_metadata) { double("vm_metadata", :namespace => "default") }
    let(:provider_vm) { double("provider_vm", :metadata => vm_metadata) }

    it "supports?(:terminate)" do
      expect(vm.supports?(:terminate)).to be_truthy
    end

    context 'running vm' do
      it 'removes an running vm from kubevirt provider' do
        allow(infra_manager).to receive(:with_provider_connection).and_yield(connection)
        expect(connection).to receive(:delete_namespaced_virtual_machine).with(vm.name, vm.location, any_args)

        vm.raw_destroy
      end
    end

    context 'stopped vm' do
      it 'removes a stopped vm from kubevirt provider' do
        allow(infra_manager).to receive(:with_provider_connection).and_yield(connection)
        expect(connection).to receive(:delete_namespaced_virtual_machine).with(vm.name, vm.location, any_args)

        vm.raw_destroy
      end
    end
  end
end
