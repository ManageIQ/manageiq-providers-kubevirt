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

  def dialog_name_from_automate(message = 'get_dialog_name', extra_attrs = {'platform' => 'kubevirt'})
    super(message, extra_attrs)
  end

  def source_ems
    src = get_source_and_targets
    load_ar_obj(src[:ems])
  end
end
