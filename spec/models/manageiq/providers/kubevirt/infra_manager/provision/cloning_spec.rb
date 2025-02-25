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
    let(:template) do
      require "kubeclient"
      Kubeclient::Resource.new(
        :kind       => "Template",
        :metadata   => {:name => "centos-stream8-desktop-large", :namespace => "openshift", :uid => "8c37cebc-c27c-4c39-ac89-777ddb2c1115"},
        :objects    => [Kubeclient::Resource.new(:apiVersion => "kubevirt.io/v1", :kind => "VirtualMachine", :metadata => {:name => "${NAME}"})],
        :parameters => [Kubeclient::Resource.new(:name => "NAME"), Kubeclient::Resource.new(:name => "CLOUD_USER_PASSWORD")]
      )
    end

    it "calls clone on template" do
      allow(source).to receive(:provider_object).and_return(template)

      subject.source  = source
      subject.options = options

      connection = double("Kubevirt::DefaultApi")

      new_vm = Kubevirt::V1VirtualMachine.new(:metadata => Kubevirt::K8sIoApimachineryPkgApisMetaV1ObjectMeta.new(:uid => SecureRandom.uuid))
      allow(connection).to receive(:create_namespaced_virtual_machine).with(namespace, hash_including(:metadata => hash_including(:name => "test"))).and_return(new_vm, 200, {})
      allow(source).to     receive(:with_provider_connection).and_yield(connection)

      subject.start_clone(:name => "test")

      expect(subject.phase_context[:new_vm_ems_ref]).to eq(new_vm.metadata.uid)
    end
  end
end
