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

#
# This class contains static methods that build the data structures used by the graph refresh
# persister to map collected objects to the corresponding database objects.
#
class ManageIQ::Providers::Kubevirt::Inventory::Collections < ManagerRefresh::InventoryCollectionDefault::InfraManager 
  class << self
    def hardwares(extra_attributes = {})
      attributes = {
        model_class: ::Hardware,
        inventory_object_attributes: [
          :memory_mb,
        ]
      }
      super(attributes.merge!(extra_attributes))
    end

    def hosts(extra_attributes = {})
      attributes = {
        model_class: ::Host,
        inventory_object_attributes: [
          :connection_state,
          :ems_cluster,
          :ems_ref,
          :ems_ref_obj,
          :hostname,
          :ipaddress,
          :ipmi_address,
          :name,
          :power_state,
          :type,
          :uid_ems,
          :vmm_buildnumber,
          :vmm_product,
          :vmm_vendor,
          :vmm_version,
        ]
      }
      super(attributes.merge!(extra_attributes))
    end

    def host_operating_systems(extra_attributes = {})
      attributes = {
        model_class: ::OperatingSystem,
        inventory_object_attributes: [
          :name,
          :product_name,
          :product_type,
          :system_type,
          :version,
        ]
      }
      super(attributes.merge!(extra_attributes))
    end

    def vms(extra_attributes = {})
      attributes = {
        model_class: ::ManageIQ::Providers::Kubevirt::InfraManager::Vm,
        inventory_object_attributes: [
          :boot_time,
          :connection_state,
          :ems_cluster,
          :ems_ref,
          :ems_ref_obj,
          :host,
          :location,
          :memory_limit,
          :memory_reserve,
          :name,
          :raw_power_state,
          :storage,
          :storages,
          :template,
          :type,
          :uid_ems,
          :vendor,
        ]
      }
      super(attributes.merge!(extra_attributes))
    end

    def miq_templates(extra_attributes = {})
      attributes = {
        model_class: ::ManageIQ::Providers::Kubevirt::InfraManager::Template,
        inventory_object_attributes: [
          :boot_time,
          :connection_state,
          :ems_cluster,
          :ems_ref,
          :ems_ref_obj,
          :host,
          :location,
          :memory_limit,
          :memory_reserve,
          :name,
          :raw_power_state,
          :storage,
          :storages,
          :template,
          :type,
          :uid_ems,
          :vendor,
        ]
      }
      super(attributes.merge!(extra_attributes))
    end
  end
end
