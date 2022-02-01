FactoryBot.define do
  factory :ems_kubevirt,
          :aliases => ["manageiq/providers/kubevirt/infra_manager"],
          :class   => "ManageIQ::Providers::Kubevirt::InfraManager",
          :parent  => :ems_infra do
    parent_manager { FactoryBot.create(:ems_container) }
  end
end
