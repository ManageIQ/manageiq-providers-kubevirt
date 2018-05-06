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
# This class is responsible for parsing the inventory for partial refreshes.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser::PartialRefresh < ManageIQ::Providers::Kubevirt::Inventory::Parser
  def parse
    # Get the notices from the collector:
    nodes = collector.nodes
    offline_vms = collector.offline_vms
    live_vms = collector.live_vms
    templates = collector.templates

    # We need to find the identifiers of the objects *before* removing notices of type `DELETED`, because we need the
    # identifiers of all the objects, even of those that have been deleted.
    host_ids = get_object_ids(nodes)
    vm_ids = get_object_ids(offline_vms)
    template_ids = get_object_ids(templates)

    # Build the list of identifiers for built-in objects:
    cluster_ids = [CLUSTER_ID]
    storage_ids = [STORAGE_ID]

    # In order to remove objects from the database we need to include the identifiers, but not the actual data, so we
    # must now discard all the notices of type `DELETED`.
    discard_deleted_notices(nodes)
    discard_deleted_notices(offline_vms)
    discard_deleted_notices(live_vms)
    discard_deleted_notices(templates)

    # Create the collections:
    @cluster_collection = persister.cluster_collection(:targeted => true, :ids => cluster_ids)
    @host_collection = persister.host_collection(:targeted => true, :ids => host_ids)
    @host_storage_collection = persister.host_storage_collection(:targeted => true)
    @hw_collection = persister.hw_collection(:targeted => true)
    @network_collection = persister.network_collection(:targeted => true)
    @os_collection = persister.os_collection(:targeted => true)
    @storage_collection = persister.storage_collection(:targeted => true, :ids => storage_ids)
    @template_collection = persister.template_collection(:targeted => true, :ids => template_ids)
    @vm_collection = persister.vm_collection(:targeted => true, :ids => vm_ids)
    @vm_os_collection = persister.vm_os_collection(:targeted => true, :ids => vm_ids)
    @disk_collection = persister.disk_collection(:targeted => true, :ids => vm_ids)

    # We need to add the built-in objects, otherwise other objects that reference them are removed:
    add_builtin_clusters
    add_builtin_storages

    # Process the real objects:
    process_nodes(nodes)
    process_offline_vms(offline_vms)
    process_live_vms(live_vms)
    process_templates(templates)
  end

  private

  def get_object_ids(notices)
    ids = notices.map { |notice| notice.metadata.uid }
    ids.uniq!
    ids
  end

  def discard_deleted_notices(notices)
    notices.reject! { |notice| notice.type == 'DELETED' }
  end
end
