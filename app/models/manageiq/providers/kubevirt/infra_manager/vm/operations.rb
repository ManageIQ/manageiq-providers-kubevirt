module ManageIQ::Providers::Kubevirt::InfraManager::Vm::Operations
  extend ActiveSupport::Concern
  include Power

  included do
    supports(:terminate) { unsupported_reason(:control) }
  end

  def raw_destroy
    require 'fog/kubevirt'
    ext_management_system.with_provider_connection(:namespace => location) do |connection|
      # Retrieve the details of the virtual machine:
      begin
        vm_instance = connection.vm_instance(name)
      rescue Fog::Kubevirt::Errors::ClientError
        # the virtual machine instance doesn't exist
        vm_instance = nil
      end

      # delete vm instance
      connection.delete_vm_instance(name, location) unless vm_instance.nil?
    end
  end
end
