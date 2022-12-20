require './spec/support/file_helpers'

RSpec.configure do |c|
  c.include FileHelpers
end

describe ManageIQ::Providers::Kubevirt::InfraManager::Provision do
  context "Cloning" do
    it "calls clone on template" do
      source = FactoryBot.create(:template_kubevirt)
      subject.source = source
      connection = double("connection")

      template = double("template")
      allow(template).to receive(:name).and_return("example")

      vm = double("vm")
      allow(vm).to receive(:uid).and_return("7e6fb1ac-00ef-11e8-8840-525400b2cba8")

      allow(connection).to receive(:template).and_return(template)
      allow(connection).to receive(:vm).and_return(vm)
      allow(source).to receive(:with_provider_connection).and_yield(connection)
      allow(source).to receive(:name).and_return("test")

      expect(template).to receive(:clone)

      subject.start_clone(:name => "test")
    end
  end
end
