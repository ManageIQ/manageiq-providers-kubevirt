FactoryGirl.define do
  factory :vm_kubevirt, :class => "ManageIQ::Providers::Kubevirt::InfraManager::Vm", :parent => :vm_infra do
    vendor          "kubevirt"
    raw_power_state "up"
  end
end
