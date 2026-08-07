describe ManageIQ::Providers::Kubevirt::InfraManager::MetricsCapture do
  let(:ems) { FactoryBot.create(:ems_kubevirt, :with_metrics_endpoint) }
  let(:hardware) { FactoryBot.create(:hardware, :cpu1x1, :ram1GB) }
  let(:host) { FactoryBot.create(:host_kubevirt, :ext_management_system => ems, :name => "test-host") }
  let(:vm) { FactoryBot.create(:vm_kubevirt, :ext_management_system => ems, :hardware => hardware, :host => host) }
  let(:template) { FactoryBot.create(:template_kubevirt, :ext_management_system => ems) }

  context "#perf_capture_object" do
    it "returns the correct class" do
      expect(ems.perf_capture_object.class).to eq(described_class)
    end
  end

  context "#build_capture_context!" do
    it "detect prometheus metrics provider" do
      metric_capture = described_class.new(vm)
      context        = metric_capture.build_capture_context!(ems, vm, 5.minutes.ago, 0.minutes.ago)

      expect(context).to be_a(described_class::PrometheusCaptureContext)
    end

    context "on an invalid target" do
      it "raises an exception" do
        metric_capture = described_class.new(template)

        expect { metric_capture.build_capture_context!(ems, template, 5.minutes.ago, 0.minutes.ago) }
          .to raise_error(described_class::TargetValidationWarning, "no associated hardware")
      end
    end
  end

  context "#perf_capture_all_queue" do
    context "with a missing metrics endpoint" do
      let(:ems) { FactoryBot.create(:ems_kubevirt) }

      it "returns no objects" do
        expect(ems.perf_capture_object.perf_capture_all_queue).to be_empty
      end
    end

    context "with invalid authentication on the metrics endpoint" do
      let(:ems) { FactoryBot.create(:ems_kubevirt, :with_metrics_endpoint, :with_invalid_auth) }

      it "returns no objects" do
        expect(ems.perf_capture_object.perf_capture_all_queue).to be_empty
      end
    end
  end

  context "#perf_collect_metrics" do
    it "fails when no cpu cores are defined" do
      vm.hardware.cpu_total_cores = nil
      expect { vm.perf_collect_metrics('interval_name') }.to raise_error(described_class::TargetValidationError)
    end

    it "fails when memory is not defined" do
      vm.hardware.memory_mb = nil
      expect { vm.perf_collect_metrics('interval_name') }.to raise_error(described_class::TargetValidationError)
    end
  end
end
