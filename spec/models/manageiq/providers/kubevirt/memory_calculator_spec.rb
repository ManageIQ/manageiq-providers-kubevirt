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

describe ManageIQ::Providers::Kubevirt::MemoryCalculator do
  describe '.convert' do
    it 'converts correctly units that correspond to powers of 10' do
      expect(described_class.convert(1, 'KB', 'B')).to eq(10**3)
      expect(described_class.convert(1, 'MB', 'B')).to eq(10**6)
      expect(described_class.convert(1, 'GB', 'B')).to eq(10**9)
      expect(described_class.convert(1, 'TB', 'B')).to eq(10**12)
      expect(described_class.convert(1, 'PB', 'B')).to eq(10**15)
      expect(described_class.convert(1, 'EB', 'B')).to eq(10**18)
      expect(described_class.convert(1, 'ZB', 'B')).to eq(10**21)
      expect(described_class.convert(1, 'YB', 'B')).to eq(10**24)
    end

    it 'converts correctly units that correspond to powers of 2' do
      expect(described_class.convert(1, 'KiB', 'B')).to eq(2**10)
      expect(described_class.convert(1, 'MiB', 'B')).to eq(2**20)
      expect(described_class.convert(1, 'GiB', 'B')).to eq(2**30)
      expect(described_class.convert(1, 'TiB', 'B')).to eq(2**40)
      expect(described_class.convert(1, 'PiB', 'B')).to eq(2**50)
      expect(described_class.convert(1, 'EiB', 'B')).to eq(2**60)
      expect(described_class.convert(1, 'ZiB', 'B')).to eq(2**70)
      expect(described_class.convert(1, 'YiB', 'B')).to eq(2**80)
    end

    it 'converts correclty powers of 10 to powers of 2' do
      expect(described_class.convert(1000, 'KB', 'KiB')).to eq(976)
      expect(described_class.convert(1000, 'MB', 'MiB')).to eq(953)
      expect(described_class.convert(1000, 'GB', 'GiB')).to eq(931)
      expect(described_class.convert(1000, 'TB', 'TiB')).to eq(909)
      expect(described_class.convert(1000, 'PB', 'PiB')).to eq(888)
      expect(described_class.convert(1000, 'EB', 'EiB')).to eq(867)
      expect(described_class.convert(1000, 'ZB', 'ZiB')).to eq(847)
      expect(described_class.convert(1000, 'YB', 'YiB')).to eq(827)
    end

    it 'converts correclty powers of 2 to powers of 10' do
      expect(described_class.convert(1000, 'KiB', 'KB')).to eq(1024)
      expect(described_class.convert(1000, 'MiB', 'MB')).to eq(1048)
      expect(described_class.convert(1000, 'GiB', 'GB')).to eq(1073)
      expect(described_class.convert(1000, 'TiB', 'TB')).to eq(1099)
      expect(described_class.convert(1000, 'PiB', 'PB')).to eq(1125)
      expect(described_class.convert(1000, 'EiB', 'EB')).to eq(1152)
      expect(described_class.convert(1000, 'ZiB', 'ZB')).to eq(1180)
      expect(described_class.convert(1000, 'YiB', 'YB')).to eq(1208)
    end

    it 'converts to smaller powers of 10 correclty' do
      expect(described_class.convert(1, 'KB', 'B')).to eq(10**3)
      expect(described_class.convert(1, 'MB', 'KB')).to eq(10**3)
      expect(described_class.convert(1, 'GB', 'MB')).to eq(10**3)
      expect(described_class.convert(1, 'TB', 'GB')).to eq(10**3)
      expect(described_class.convert(1, 'PB', 'TB')).to eq(10**3)
      expect(described_class.convert(1, 'EB', 'PB')).to eq(10**3)
      expect(described_class.convert(1, 'ZB', 'EB')).to eq(10**3)
      expect(described_class.convert(1, 'YB', 'ZB')).to eq(10**3)
    end

    it 'converts to smaller powers of 2 correclty' do
      expect(described_class.convert(1, 'KiB', 'B')).to eq(2**10)
      expect(described_class.convert(1, 'MiB', 'KiB')).to eq(2**10)
      expect(described_class.convert(1, 'GiB', 'MiB')).to eq(2**10)
      expect(described_class.convert(1, 'TiB', 'GiB')).to eq(2**10)
      expect(described_class.convert(1, 'PiB', 'TiB')).to eq(2**10)
      expect(described_class.convert(1, 'EiB', 'PiB')).to eq(2**10)
      expect(described_class.convert(1, 'ZiB', 'EiB')).to eq(2**10)
      expect(described_class.convert(1, 'YiB', 'ZiB')).to eq(2**10)
    end

    it 'converts to larger powers of 10 correclty' do
      expect(described_class.convert(10**3, 'B', 'KB')).to eq(1)
      expect(described_class.convert(10**3, 'KB', 'MB')).to eq(1)
      expect(described_class.convert(10**3, 'MB', 'GB')).to eq(1)
      expect(described_class.convert(10**3, 'GB', 'TB')).to eq(1)
      expect(described_class.convert(10**3, 'TB', 'PB')).to eq(1)
      expect(described_class.convert(10**3, 'PB', 'EB')).to eq(1)
      expect(described_class.convert(10**3, 'EB', 'ZB')).to eq(1)
      expect(described_class.convert(10**3, 'ZB', 'YB')).to eq(1)
    end

    it 'converts to larger powers of 2 correclty' do
      expect(described_class.convert(2**10, 'B', 'KiB')).to eq(1)
      expect(described_class.convert(2**10, 'KiB', 'MiB')).to eq(1)
      expect(described_class.convert(2**10, 'MiB', 'GiB')).to eq(1)
      expect(described_class.convert(2**10, 'GiB', 'TiB')).to eq(1)
      expect(described_class.convert(2**10, 'TiB', 'PiB')).to eq(1)
      expect(described_class.convert(2**10, 'PiB', 'EiB')).to eq(1)
      expect(described_class.convert(2**10, 'EiB', 'ZiB')).to eq(1)
      expect(described_class.convert(2**10, 'ZiB', 'YiB')).to eq(1)
    end
  end
end
