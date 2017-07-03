#
# Copyright (c) 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class ManageIQ::Providers::KubeVirt::InfraManager::ProvisionWorkflow < MiqProvisionInfraWorkflow
  def self.default_dialog_file
    'miq_provision_dialogs'
  end

  def self.provider_model
    ManageIQ::Providers::KubeVirt::InfraManager
  end

  def supports_pxe?
    get_value(@values[:provision_type]).to_s == 'pxe'
  end

  def supports_iso?
    get_value(@values[:provision_type]).to_s == 'iso'
  end

  def supports_native_clone?
    get_value(@values[:provision_type]).to_s == 'native_clone'
  end

  def supports_linked_clone?
    supports_native_clone? && get_value(@values[:linked_clone])
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

  def update_field_visibility_linked_clone(_options = {}, f)
    show_flag = supports_native_clone? ? :edit : :hide
    f[show_flag] << :linked_clone

    show_flag = supports_linked_clone? ? :hide : :edit
    f[show_flag] << :disk_format
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
    return [] if (src = resources_for_ui).blank?
    result = super

    if supports_linked_clone?
      s_id = load_ar_obj(src[:vm]).storage_id
      result = result.select { |s| s.id == s_id }
    end

    result.select { |s| s.storage_domain_type == "data" }
  end

  def source_ems
    src = get_source_and_targets
    load_ar_obj(src[:ems])
  end

  def filter_allowed_hosts(all_hosts)
    all_hosts
  end
end
