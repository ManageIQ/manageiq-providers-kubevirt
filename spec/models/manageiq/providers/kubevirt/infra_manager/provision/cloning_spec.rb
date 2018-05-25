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
    it "calls clone on template" do
      source = FactoryGirl.create(:template_kubevirt)
      subject.source = source
      connection = double("connection")

      template = double("template")
      allow(template).to receive(:name).and_return("example")

      offlinevm = double("offlinevm")
      allow(offlinevm).to receive(:uid).and_return("7e6fb1ac-00ef-11e8-8840-525400b2cba8")

      allow(connection).to receive(:template).and_return(template)
      allow(connection).to receive(:offline_vm).and_return(offlinevm)
      allow(source).to receive(:with_provider_connection).and_yield(connection)
      allow(source).to receive(:name).and_return("test")

      expect(template).to receive(:clone)

      subject.start_clone(:name => "test")
    end
  end
end
