module ManageIQ
  module Providers
    module KubeVirt
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::KubeVirt
      end
    end
  end
end
