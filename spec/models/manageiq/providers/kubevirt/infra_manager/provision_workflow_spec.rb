describe ManageIQ::Providers::Kubevirt::InfraManager::ProvisionWorkflow do
  let(:ems)      { FactoryBot.create(:ems_kubevirt) }
  let(:template) { FactoryBot.create(:template_kubevirt, :ext_management_system => ems) }
  let(:workflow) do
    described_class.new(
      {:src_vm_id => template.id},
      FactoryBot.create(:user_with_group),
      :skip_dialog_load => true
    )
  end

  describe '#allowed_provision_types' do
    it 'only allows native_clone' do
      expect(workflow.allowed_provision_types).to eq("native_clone" => "Native Clone")
    end
  end
end
