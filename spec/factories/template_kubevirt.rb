FactoryBot.define do
  factory(:template_kubevirt, :class => "ManageIQ::Providers::Kubevirt::InfraManager::Template", :parent => :template_infra) { vendor "kubevirt" }
end
