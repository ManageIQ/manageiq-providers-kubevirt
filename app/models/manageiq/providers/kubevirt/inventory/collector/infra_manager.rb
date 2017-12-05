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
# This class is responsible for collecting the complete inventory for the provider.
#
class ManageIQ::Providers::Kubevirt::Inventory::Collector::InfraManager < ManagerRefresh::Inventory::Collector
  def initialize(ems, target)
    @ems = ems
  end

  def nodes
    @ems.with_provider_connection(nil, &:nodes)
  end

  def virtual_machine_templates
    @ems.with_provider_connection(nil, &:virtual_machine_templates)
  end

  def stored_virtual_machines
    @ems.with_provider_connection(nil, &:stored_virtual_machines)
  end

  def virtual_machines
    @ems.with_provider_connection(nil, &:virtual_machines)
  end
end
