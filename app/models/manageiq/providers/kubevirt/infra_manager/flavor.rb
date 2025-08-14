class ManageIQ::Providers::Kubevirt::InfraManager::Flavor < Flavor
  belongs_to :ext_management_system, :foreign_key => :ems_id, :class_name => "ManageIQ::Providers::InfraManager"
end
