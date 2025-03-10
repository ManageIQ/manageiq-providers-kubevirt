require './spec/support/file_helpers'

RSpec.configure do |c|
  c.include FileHelpers
end

describe ManageIQ::Providers::Kubevirt::InfraManager::Provision do
  context "Cloning" do
    let(:source)     { FactoryBot.create(:template_kubevirt, :location => namespace) }
    let(:options)    { {:cores_per_socket => [1, "1"], :vm_memory => ["1024", "1024"], :root_password => "1234"} }
    let(:connection) { double("Kubevirt::DefaultApi") }
    let(:namespace)  { "openshift" }
    let(:parameters) { [Kubeclient::Resource.new(:name => "NAME"), Kubeclient::Resource.new(:name => "CLOUD_USER_PASSWORD")] }
    let(:vm_object)  { Kubeclient::Resource.new(:apiVersion => "kubevirt.io/v1", :kind => "VirtualMachine", :metadata => {:name => "${NAME}"}) }
    let(:objects)    { [vm_object] }
    let(:template) do
      require "kubeclient"
      Kubeclient::Resource.new(
        :kind       => "Template",
        :metadata   => {:name => "centos-stream8-desktop-large", :namespace => "openshift", :uid => "8c37cebc-c27c-4c39-ac89-777ddb2c1115"},
        :objects    => objects,
        :parameters => parameters
      )
    end
    let(:new_vm) do
      require 'kubevirt'
      Kubevirt::V1VirtualMachine.new(
        :metadata => Kubevirt::K8sIoApimachineryPkgApisMetaV1ObjectMeta.new(:uid => SecureRandom.uuid),
        :spec     => Kubevirt::V1VirtualMachineSpec.new(:template => Kubevirt::V1VirtualMachineInstanceTemplateSpec.new)
      )
    end

    before do
      allow(source).to receive(:provider_object).and_return(template)
      subject.source  = source
      subject.options = options
    end

    it "calls clone on template" do
      connection = double("Kubevirt::DefaultApi")

      allow(connection).to receive(:create_namespaced_virtual_machine).with(namespace, hash_including(:metadata => hash_including(:name => "test"))).and_return(new_vm, 200, {})
      allow(source).to     receive(:with_provider_connection).and_yield(connection)

      subject.start_clone(:name => "test")

      expect(subject.phase_context[:new_vm_ems_ref]).to eq(new_vm.metadata.uid)
    end

    context "with hash parameters" do
      let(:options)    { {:cores_per_socket => {:cores => 2, :sockets => 2, :threads => 4}, :vm_memory => ["1024", "1024"], :root_password => "1234"} }
      let(:parameters) { [Kubeclient::Resource.new(:name => "NAME"), Kubeclient::Resource.new(:name => "CLOUD_USER_PASSWORD"), Kubeclient::Resource.new(:name => "CPU_CORES")] }
      let(:vm_object)  { Kubeclient::Resource.new(:apiVersion => "kubevirt.io/v1", :kind => "VirtualMachine", :metadata => {:name => "${NAME}"}, :spec => {:domain => "${CPU_CORES}"}) }

      it "replaces spec.domain.cpu with the hash" do
        allow(connection)
          .to receive(:create_namespaced_virtual_machine)
          .with(namespace, hash_including(:spec => hash_including(:domain => {:cores => 2, :sockets => 2, :threads => 4})))
          .and_return(new_vm, 200, {})
        allow(source).to receive(:with_provider_connection).and_yield(connection)

        subject.start_clone(:name => "test")
      end
    end

    context "with persistent volume claims" do
      let(:pvc_object) { Kubeclient::Resource.new(:kind => "PersistentVolumeClaim") }
      let(:objects)    { [vm_object, pvc_object] }

      it "creates the persistent volume claims" do
        connection = double("Kubevirt::DefaultApi")
        kubeclient = double("Kubeclient")

        allow(connection).to receive(:create_namespaced_virtual_machine).with(namespace, hash_including(:metadata => hash_including(:name => "test"))).and_return(new_vm, 200, {})
        allow(source).to     receive(:with_provider_connection).and_yield(connection)
        allow(subject).to    receive(:kubeclient).and_return(kubeclient)

        expect(kubeclient).to receive(:create_persistent_volume_claim)

        subject.start_clone(:name => "test")
      end

      it "cleans up pvcs on failure" do
        connection = double("Kubevirt::DefaultApi")
        kubeclient = double("Kubeclient")

        allow(connection).to receive(:create_namespaced_virtual_machine).and_raise(RuntimeError)
        allow(source).to     receive(:with_provider_connection).and_yield(connection)
        allow(subject).to    receive(:kubeclient).and_return(kubeclient)

        expect(kubeclient).to receive(:create_persistent_volume_claim)
        expect(kubeclient).to receive(:delete_persistent_volume_claim)

        subject.start_clone(:name => "test")
      end
    end
  end
end
