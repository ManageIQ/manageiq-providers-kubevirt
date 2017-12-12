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
# This class contains functions that do memory calculations.
#
class ManageIQ::Providers::Kubevirt::MemoryCalculator
  #
  # Converts a value from one unit to another unit
  #
  # @param value [Integer] The value to convert.
  # @param from_unit [String] ('B') The name of the unit used by the value, for example `KB`.
  # @param to_unit [String] ('B') The name of the unit to convert to, for example `GiB`.
  # @return [Integer] The converted value, rounded down to the nearest integer.
  #
  def self.convert(value, from_unit, to_unit)
    from_unit ||= 'B'
    from_multiplier = MEMORY_UNIT_MULTIPLIERS[from_unit]
    to_unit ||= 'B'
    to_multiplier = MEMORY_UNIT_MULTIPLIERS[to_unit]
    value * from_multiplier / to_multiplier
  end

  private

  MEMORY_UNIT_MULTIPLIERS = {
    'B' => 1,

    'KB' => 10**3,
    'MB' => 10**6,
    'GB' => 10**9,
    'TB' => 10**12,
    'PB' => 10**15,
    'EB' => 10**18,
    'ZB' => 10**21,
    'YB' => 10**24,

    'KiB' => 2**10,
    'MiB' => 2**20,
    'GiB' => 2**30,
    'TiB' => 2**40,
    'PiB' => 2**50,
    'EiB' => 2**60,
    'ZiB' => 2**70,
    'YiB' => 2**80
  }.freeze
end
