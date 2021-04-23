if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq-providers-kubevirt"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::Kubevirt::Engine.root, 'spec/vcr_cassettes')

  secrets = Rails.application.secrets
  secrets.kubevirt&.each_key do |secret|
    config.define_cassette_placeholder(secrets.kubevirt_defaults[secret]) { secrets.kubevirt[secret] }
  end
end
