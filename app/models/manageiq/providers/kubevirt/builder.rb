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
# This class is responsible for creating objects, as instructed by the ManageIQ core. For example,
# when the ManageIQ core needs to create an inventory object it will call the `build_inventory`
# method of this class.
#
class ManageIQ::Providers::Kubevirt::Builder
  class << self
    def build_inventory(manager, target)
      # Create the collector, parser and persister:
      collector = ManageIQ::Providers::Kubevirt::Inventory::Collector.new(manager, target)
      parser = ManageIQ::Providers::Kubevirt::Inventory::Parser.new
      persister = ManageIQ::Providers::Kubevirt::Inventory::Persister.new(manager, target, collector)

      # Create and return the inventory:
      ManageIQ::Providers::Kubevirt::Inventory.new(persister, collector, [parser])
    end
  end
end
