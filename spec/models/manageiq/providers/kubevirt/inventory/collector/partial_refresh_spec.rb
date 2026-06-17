autoload(:Kubeclient, 'kubeclient')

describe ManageIQ::Providers::Kubevirt::Inventory::Collector::PartialRefresh do
  let(:ems)       { FactoryBot.create(:ems_kubevirt) }
  let(:collector) { described_class.new(ems, notices) }
  let(:notices)   { [] }

  context "with no notices" do
    it "collections are empty" do
      expect(collector.nodes).to          be_empty
      expect(collector.vms).to            be_empty
      expect(collector.vm_instances).to   be_empty
      expect(collector.instance_types).to be_empty
    end
  end

  context "with a vm notice" do
    let(:vm)        { Kubeclient::Resource.new(:apiVersion => "kubevirt.io/v1", :kind => "VirtualMachine", :metadata => {:name => "my-vm", :namespace => "default", :uid => SecureRandom.uuid})}
    let(:vm_notice) { Kubeclient::Resource.new(:type => "MODIFIED", :object => vm) }
    let(:notices)   { [vm_notice] }

    it "#vms" do
      expect(collector.vms).to include(vm_notice)
    end

    context "with multiple notices for the same object" do
      let(:vm_notice2) { Kubeclient::Resource.new(:type => "MODIFIED", :object => vm) }
      let(:notices)    { [vm_notice, vm_notice2] }

      it "only exposes a single notice" do
        expect(collector.vms.count).to eq(1)
      end
    end
  end
end
