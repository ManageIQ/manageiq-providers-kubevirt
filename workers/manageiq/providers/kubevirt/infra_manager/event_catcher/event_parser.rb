require 'manageiq/providers/kubernetes/workers/event_parser'

module ManageIQ
  module Providers
    module Kubevirt
      module Workers
        module InfraManager
          class EventParser < ManageIQ::Providers::Kubernetes::Workers::EventParser
            ENABLED_EVENTS = {
              'VirtualMachine'         => %w[Created Started Migrated SuccessfulCreate SuccessfulDelete ShuttingDown],
              'VirtualMachineInstance' => %w[Created Started Migrated SuccessfulCreate SuccessfulDelete ShuttingDown]
            }.freeze

            def self.extract_event_data(event)
              event_data = super
              return event_data if event_data.empty?

              if ENABLED_EVENTS.key?(event_data[:kind])
                event_data[:vm_name]    = event_data[:name]
                event_data[:vm_ems_ref] = event_data[:uid]
              end

              event_data
            end

            def self.event_to_hash_from_data(event_data, ems_id = nil)
              hash          = super
              hash[:source] = 'KUBEVIRT'

              if ENABLED_EVENTS.key?(event_data[:kind])
                hash[:vm_name]    = event_data[:vm_name]
                hash[:vm_ems_ref] = event_data[:vm_ems_ref]
              end

              hash
            end
          end
        end
      end
    end
  end
end
