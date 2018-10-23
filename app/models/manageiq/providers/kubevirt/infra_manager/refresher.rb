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
# This class is responsible for the inventory refresh process.
#
class ManageIQ::Providers::Kubevirt::InfraManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
  def collect_inventory_for_targets(ems, targets)
    targets_with_data = targets.collect do |target|
      _log.info("Filtering inventory for #{target.class} [#{target.name}] id: [#{target.id}]...")

      data = ManageIQ::Providers::Kubevirt::Inventory.build(ems, target)

      _log.info("Filtering inventory...Complete")
      [target, data]
    end

    targets_with_data
  end

  def parse_targeted_inventory(ems, _target, inventory)
    log_header = format_ems_for_logging(ems)
    _log.debug("#{log_header} Parsing inventory...")
    hashes, = Benchmark.realtime_block(:parse_inventory) do
      inventory.inventory_collections
    end
    _log.debug("#{log_header} Parsing inventory...Complete")

    hashes
  end
end
