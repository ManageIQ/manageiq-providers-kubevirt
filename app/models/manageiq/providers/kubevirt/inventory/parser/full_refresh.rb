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
# This class is responsible for parsing the inventory for full refreshes.
#
class ManageIQ::Providers::Kubevirt::Inventory::Parser::FullRefresh < ManageIQ::Providers::Kubevirt::Inventory::Parser
  def parse
    # Get the objects from the collector:
    nodes = collector.nodes
    offline_vms = collector.offline_vms
    live_vms = collector.live_vms
    templates = collector.templates

    # Create the collections:
    @cluster_collection = persister.cluster_collection
    @host_collection = persister.host_collection
    @host_storage_collection = persister.host_storage_collection
    @hw_collection = persister.hw_collection
    @os_collection = persister.os_collection
    @storage_collection = persister.storage_collection
    @template_collection = persister.template_collection
    @vm_collection = persister.vm_collection

    # Add the built-in objects:
    add_builtin_clusters
    add_builtin_storages

    # Process the real objects:
    process_nodes(nodes)
    process_offline_vms(offline_vms)
    process_live_vms(live_vms)
    process_templates(templates)
  end
end
