class ManageIQ::Providers::Kubevirt::InfraManager::ProvisionWorkflow < MiqProvisionInfraWorkflow
  def self.default_dialog_file
    'miq_provision_dialogs'
  end

  def self.provider_model
    ManageIQ::Providers::Kubevirt::InfraManager
  end

  def supports_pxe?
    get_value(@values[:provision_type]).to_s == 'pxe'
  end

  def supports_iso?
    get_value(@values[:provision_type]).to_s == 'iso'
  end

  def supports_customization_template?
    true
  end

  def supports_native_clone?
    get_value(@values[:provision_type]).to_s == 'native_clone'
  end

  def allowed_provision_types(_options = {})
    {
      "native_clone" => "Native Clone"
    }
  end

  def dialog_name_from_automate(message = 'get_dialog_name')
    super(message, {'platform' => 'kubevirt'})
  end

  def update_field_visibility
    super(:force_platform => 'linux')
  end

  def allowed_datacenters(_options = {})
    super.slice(datacenter_by_vm.try(:id))
  end

  def datacenter_by_vm
    @datacenter_by_vm ||= begin
                            vm = resources_for_ui[:vm]
                            VmOrTemplate.find(vm.id).parent_datacenter if vm
                          end
  end

  def set_on_vm_id_changed
    @datacenter_by_vm = nil
    super
  end

  def allowed_hosts_obj(_options = {})
    super(:datacenter => datacenter_by_vm)
  end

  def allowed_storages(options = {})
    return [] if resources_for_ui.blank?
    result = super
    result.select { |s| s.storage_domain_type == "data" }
  end

  def source_ems
    src = get_source_and_targets
    load_ar_obj(src[:ems])
  end
end
