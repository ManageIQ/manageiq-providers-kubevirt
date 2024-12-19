FactoryBot.define do
  factory(:host_kubevirt, :class => "ManageIQ::Providers::Kubevirt::InfraManager::Host", :traits => [:with_ref], :parent => :host) { vmm_vendor { "kubevirt" } }
end
