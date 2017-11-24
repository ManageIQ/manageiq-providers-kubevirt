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
# This class is responsible for persisting the inventory for a partial refresh.
#
class ManageIQ::Providers::Kubevirt::Inventory::Persister < ManagerRefresh::Inventory::Persister
  def cluster_collection(targeted: false, ids: [])
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.ems_clusters(
      targeted: targeted,
      manager_uuids: ids,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end

  def host_collection(targeted: false, ids: [])
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.hosts(
      targeted: targeted,
      manager_uuids: ids,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end

  def host_storage_collection(targeted: false)
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.host_storages(
      targeted: targeted,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end

  def hw_collection(targeted: false)
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.hardwares(
      targeted: targeted,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end

  def os_collection(targeted: false)
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.host_operating_systems(
      targeted: targeted,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end

  def template_collection(targeted: false, ids: [])
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.miq_templates(
      targeted: targeted,
      manager_uuids: ids,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end

  def storage_collection(targeted: false, ids: [])
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.storages(
      targeted: targeted,
      manager_uuids: ids,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end

  def vm_collection(targeted: false, ids: [])
    attributes = ManageIQ::Providers::Kubevirt::Inventory::Collections.vms(
      targeted: targeted,
      manager_uuids: ids,
      strategy: :local_db_find_missing_references
    )
    add_inventory_collection(attributes)
  end
end
