#
# Copyright (c) 2018 Red Hat, Inc.
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
require './spec/support/file_helpers'

RSpec.configure do |c|
  c.include FileHelpers
end

describe ManageIQ::Providers::Kubevirt::InfraManager::Provision do
  context "Cloning" do
    it "creates specific objects with pvc" do
      source = FactoryGirl.create(:template_kubevirt)
      subject.source = source
      connection = double("connection")

      allow(connection).to receive(:template).and_return(unprocessed_object("template.json"))
      allow(source).to receive(:with_provider_connection).and_yield(connection)
      allow(source).to receive(:name).and_return("test")
      expect(connection).to receive(:create_offline_vm) do |offline_vm|
        expect(offline_vm).not_to be_nil
        expect(offline_vm).to eq(unprocessed_hash("offline_vm.yml"))
        unprocessed_object("offlinevm.json")
      end

      expect(connection).to receive(:create_pvc) do |pvc|
        expect(pvc).not_to be_nil
        expect(pvc).to eq(unprocessed_hash("pvc.yml"))
      end

      subject.start_clone(:name => "test")
    end
  end

  it "creates object" do
    source = FactoryGirl.create(:template_kubevirt)
    subject.source = source
    connection = double("connection")

    allow(connection).to receive(:template).and_return(unprocessed_object("template_registry.json"))
    allow(source).to receive(:with_provider_connection).and_yield(connection)
    allow(source).to receive(:name).and_return("test")
    expect(connection).to receive(:create_offline_vm) do |offline_vm|
      expect(offline_vm).not_to be_nil
      expect(offline_vm).to eq(unprocessed_hash("offline_vm_registry.yml"))
      unprocessed_object("offlinevm_registry.json")
    end

    subject.start_clone(:name => "test", :memory => 4096)
  end
end
