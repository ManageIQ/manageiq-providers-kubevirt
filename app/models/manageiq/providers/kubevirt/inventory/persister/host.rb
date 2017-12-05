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
# This class is responsible for persisting the inventory for a host.
#
class ManageIQ::Providers::Kubevirt::Inventory::Persister::Host < ManagerRefresh::Inventory::Persister
  def initialize_inventory_collections
    add_inventory_collections(
      ManageIQ::Providers::Kubevirt::Inventory::Collections,
      %i(
        hardwares
        host_operating_systems
        hosts
      )
    )
  end
end
