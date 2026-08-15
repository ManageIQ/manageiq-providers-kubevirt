module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations
  extend ActiveSupport::Concern

  include Configuration
  include Power
  include Snapshot
  include Guest
  include Disk

  included do
    supports(:terminate) { unsupported_reason(:control) }
  end

  def raw_destroy
    with_provider_connection do |connection|
      connection.delete_namespaced_virtual_machine(name, location, {})
    end
  end
end
