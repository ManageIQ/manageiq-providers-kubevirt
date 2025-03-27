FactoryBot.define do
  factory :host_kubevirt, :class => "ManageIQ::Providers::Kubevirt::InfraManager::Host", :parent => :host
end
