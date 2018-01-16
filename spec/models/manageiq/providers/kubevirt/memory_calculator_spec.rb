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
      expect(described_class.convert('1KB', :b).to_i).to eq(10**3)
      expect(described_class.convert('1MB', :b).to_i).to eq(10**6)
      expect(described_class.convert('1GB', :b).to_i).to eq(10**9)
      expect(described_class.convert('1TB', :b).to_i).to eq(10**12)
      expect(described_class.convert('1PB', :b).to_i).to eq(10**15)
      expect(described_class.convert('1EB', :b).to_i).to eq(10**18)
      expect(described_class.convert('1ZB', :b).to_i).to eq(10**21)
      expect(described_class.convert('1YB', :b).to_i).to eq(10**24)
    end

    it 'converts correctly units that correspond to powers of 2' do
      expect(described_class.convert('1KiB', :b).to_i).to eq(2**10)
      expect(described_class.convert('1MiB', :b).to_i).to eq(2**20)
      expect(described_class.convert('1GiB', :b).to_i).to eq(2**30)
      expect(described_class.convert('1TiB', :b).to_i).to eq(2**40)
      expect(described_class.convert('1PiB', :b).to_i).to eq(2**50)
      expect(described_class.convert('1EiB', :b).to_i).to eq(2**60)
      expect(described_class.convert('1ZiB', :b).to_i).to eq(2**70)
      expect(described_class.convert('1YiB', :b).to_i).to eq(2**80)
    end

    it 'converts correclty powers of 10 to powers of 2' do
      expect(described_class.convert('1000KB', :kib).to_i).to eq(976)
      expect(described_class.convert('1000MB', :mib).to_i).to eq(953)
      expect(described_class.convert('1000GB', :gib).to_i).to eq(931)
      expect(described_class.convert('1000TB', :tib).to_i).to eq(909)
      expect(described_class.convert('1000PB', :pib).to_i).to eq(888)
      expect(described_class.convert('1000EB', :eib).to_i).to eq(867)
      expect(described_class.convert('1000ZB', :zib).to_i).to eq(847)
      expect(described_class.convert('1000YB', :yib).to_i).to eq(827)
    end

    it 'converts correclty powers of 2 to powers of 10' do
      expect(described_class.convert('1000KiB', :kb).to_i).to eq(1024)
      expect(described_class.convert('1000MiB', :mb).to_i).to eq(1048)
      expect(described_class.convert('1000GiB', :gb).to_i).to eq(1073)
      expect(described_class.convert('1000TiB', :tb).to_i).to eq(1099)
      expect(described_class.convert('1000PiB', :pb).to_i).to eq(1125)
      expect(described_class.convert('1000EiB', :eb).to_i).to eq(1152)
      expect(described_class.convert('1000ZiB', :zb).to_i).to eq(1180)
      expect(described_class.convert('1000YiB', :yb).to_i).to eq(1208)
    end

    it 'converts to smaller powers of 10 correclty' do
      expect(described_class.convert('1KB', 'B').to_i).to eq(10**3)
      expect(described_class.convert('1MB', 'KB').to_i).to eq(10**3)
      expect(described_class.convert('1GB', 'MB').to_i).to eq(10**3)
      expect(described_class.convert('1TB', 'GB').to_i).to eq(10**3)
      expect(described_class.convert('1PB', 'TB').to_i).to eq(10**3)
      expect(described_class.convert('1EB', 'PB').to_i).to eq(10**3)
      expect(described_class.convert('1ZB', 'EB').to_i).to eq(10**3)
      expect(described_class.convert('1YB', 'ZB').to_i).to eq(10**3)
    end

    it 'converts to smaller powers of 2 correclty' do
      expect(described_class.convert('1KiB', 'B').to_i).to eq(2**10)
      expect(described_class.convert('1MiB', 'KiB').to_i).to eq(2**10)
      expect(described_class.convert('1GiB', 'MiB').to_i).to eq(2**10)
      expect(described_class.convert('1TiB', 'GiB').to_i).to eq(2**10)
      expect(described_class.convert('1PiB', 'TiB').to_i).to eq(2**10)
      expect(described_class.convert('1EiB', 'PiB').to_i).to eq(2**10)
      expect(described_class.convert('1ZiB', 'EiB').to_i).to eq(2**10)
      expect(described_class.convert('1YiB', 'ZiB').to_i).to eq(2**10)
    end

    it 'converts to larger powers of 10 correclty' do
      expect(described_class.convert('1000b', 'kb').to_i).to eq(1)
      expect(described_class.convert('1000kb', 'mb').to_i).to eq(1)
      expect(described_class.convert('1000mb', 'gb').to_i).to eq(1)
      expect(described_class.convert('1000gb', 'tb').to_i).to eq(1)
      expect(described_class.convert('1000tb', 'pb').to_i).to eq(1)
      expect(described_class.convert('1000pb', 'eb').to_i).to eq(1)
      expect(described_class.convert('1000eb', 'zb').to_i).to eq(1)
      expect(described_class.convert('1000zb', 'yb').to_i).to eq(1)
    end

    it 'converts to larger powers of 2 correclty' do
      expect(described_class.convert('1024b', 'ki').to_i).to eq(1)
      expect(described_class.convert('1024kib', 'mi').to_i).to eq(1)
      expect(described_class.convert('1024mib', 'gi').to_i).to eq(1)
      expect(described_class.convert('1024gib', 'ti').to_i).to eq(1)
      expect(described_class.convert('1024tib', 'pi').to_i).to eq(1)
      expect(described_class.convert('1024pib', 'ei').to_i).to eq(1)
      expect(described_class.convert('1024eib', 'zi').to_i).to eq(1)
      expect(described_class.convert('1024zib', 'yi').to_i).to eq(1)
    end

    it 'accepts spaces between the numeric value and the unit suffix' do
      expect(described_class.convert('2 KiB', :b).to_i).to eq(2048)
    end

    it 'accepts spaces before the numeric value' do
      expect(described_class.convert(' 2KiB', :b).to_i).to eq(2048)
    end

    it 'accepts spaces after the unit suffix' do
      expect(described_class.convert('2KiB ', :b).to_i).to eq(2048)
    end

    it 'returns nil if no value is given' do
      expect(described_class.convert(nil, :b)).to be_nil
    end
  end
end
