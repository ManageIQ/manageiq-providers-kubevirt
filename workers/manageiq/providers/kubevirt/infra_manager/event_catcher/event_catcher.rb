require 'manageiq/providers/kubernetes/workers/event_catcher_base'
require_relative 'event_parser'

module ManageIQ
  module Providers
    module Kubevirt
      module Workers
        module InfraManager
          class EventCatcher < ManageIQ::Providers::Kubernetes::Workers::EventCatcherBase
            ENABLED_EVENTS = EventParser::ENABLED_EVENTS

            def filtered?(event_data)
              supported_reasons = ENABLED_EVENTS[event_data[:kind]] || []
              !supported_reasons.include?(event_data[:reason]) || filtered_events.include?(event_data[:event_type])
            end

            private

            # Extracts VM/VMI-specific fields and applies the KUBEVIRT source tag.
            def event_parser
              EventParser
            end

            def log_prefix
              'MIQ(ManageIQ::Providers::Kubevirt::InfraManager::EventCatcher)'
            end
          end
        end
      end
    end
  end
end
