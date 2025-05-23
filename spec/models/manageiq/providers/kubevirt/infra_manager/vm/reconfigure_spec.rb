describe ManageIQ::Providers::Kubevirt::InfraManager::Vm::Reconfigure do
  let(:ems) { FactoryBot.create(:ems_kubevirt) }
  let(:vm) { FactoryBot.create(:vm_kubevirt, :ext_management_system => ems) }
  let(:miq_server) { EvmSpecHelper.local_miq_server }

  describe "#reconfigurable?" do
    context "with an active vm" do
      it "is reconfigurable" do
        expect(vm.reconfigurable?).to be_truthy
      end
    end

    context "with an archived vm" do
      let(:ems) { nil }

      it "is not reconfigurable" do
        expect(vm.reconfigurable?).to be_falsey
      end
    end
  end

  describe "#max_vcpus" do
    let!(:host1) { FactoryBot.create(:host_kubevirt, :ext_management_system => ems, :hardware => FactoryBot.create(:hardware, :cpu2x2)) }
    let!(:host2) { FactoryBot.create(:host_kubevirt, :ext_management_system => ems, :hardware => FactoryBot.create(:hardware, :cpu4x2)) }

    it "returns the highest cpu_total_cores for all hosts in the EMS" do
      expect(vm.max_vcpus).to eq(8)
    end

    context "with a host in another EMS" do
      let(:ems2)   { FactoryBot.create(:ems_kubevirt) }
      let!(:host2) { FactoryBot.create(:host_kubevirt, :ext_management_system => ems2, :hardware => FactoryBot.create(:hardware, :cpu4x2)) }

      it "doesn't use host with more CPUs from another EMS" do
        expect(vm.max_vcpus).to eq(4)
      end
    end
  end

  describe "#max_memory_mb" do
    let!(:host1) { FactoryBot.create(:host_kubevirt, :ext_management_system => ems, :hardware => FactoryBot.create(:hardware, :memory_mb => 2_048)) }
    let!(:host2) { FactoryBot.create(:host_kubevirt, :ext_management_system => ems, :hardware => FactoryBot.create(:hardware, :memory_mb => 4_096)) }

    it "returns the highest memory_mb for all hosts in the EMS" do
      expect(vm.max_memory_mb).to eq(4_096)
    end

    context "with a host in another EMS" do
      let(:ems2)   { FactoryBot.create(:ems_kubevirt) }
      let!(:host2) { FactoryBot.create(:host_kubevirt, :ext_management_system => ems2, :hardware => FactoryBot.create(:hardware, :memory_mb => 4_096)) }

      it "doesn't use host with more memory from another EMS" do
        expect(vm.max_memory_mb).to eq(2_048)
      end
    end
  end

  describe "#build_config_spec" do
    let(:memory_mb) { "2048" }

    context "changing memory" do
      let(:options) do
        {
          :src_ids             => [vm.id],
          :vm_memory           => memory_mb,
          :request_type        => :vm_reconfigure,
          :executed_on_servers => [miq_server.id]
        }
      end

      it "returns a k8s patch object" do
        expect(vm.build_config_spec(options)).to match_array(
          [
            {"op" => "replace", "path" => "/spec/template/spec/domain/memory/guest", "value" => "2048Mi"}
          ]
        )
      end
    end

    context "changing cpu topology" do
      let(:options) do
        {
          :src_ids             => [vm.id],
          :cores_per_socket    => 2,
          :number_of_sockets   => 2,
          :number_of_cpus      => 4,
          :request_type        => :vm_reconfigure,
          :executed_on_servers => [miq_server.id]
        }
      end

      it "returns a k8s patch object" do
        expect(vm.build_config_spec(options)).to match_array(
          [
            {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/sockets", "value" => 2},
            {"op" => "replace", "path" => "/spec/template/spec/domain/cpu/cores",   "value" => 2}
          ]
        )
      end
    end
  end
end
