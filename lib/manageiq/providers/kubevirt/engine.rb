module ManageIQ
  module Providers
    module Kubevirt
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Kubevirt

        def self.plugin_name
          _('KubeVirt Provider')
        end
      end
    end
  end
end
