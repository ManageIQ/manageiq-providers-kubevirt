describe ManageIQ::Providers::Kubevirt::InfraManager::Vm::Reconfigure do
  let(:vm) { FactoryBot.create(:kubevirt_vm) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }

  describe "reconfigurable?" do

  end

  describe "#max_vcpus" do

  end

  describe "#max_memory_mb" do

  end

  describe "#build_config_spec" do
    let(:memory_mb) { "2048" }
    let(:options) do
      {
        :src_ids             => [vm.id],
        :vm_memory           => memory_mb,
        :cores_per_socket    => 2,
        :number_of_sockets   => 2,
        :number_of_cpus      => 4,
        :request_type        => :vm_reconfigure,
        :executed_on_servers => [miq_server.id]
      }
    end

    it "returns a k8s patch object" do
      vm.build_config_spec(options)
    end
  end
end
