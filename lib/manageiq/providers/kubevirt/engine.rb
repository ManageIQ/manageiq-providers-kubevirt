module ManageIQ
  module Providers
    module Kubevirt
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::Kubevirt

        config.autoload_paths << root.join('lib').to_s

        initializer :append_secrets do |app|
          app.config.paths["config/secrets"] << root.join("config", "secrets.defaults.yml").to_s
          app.config.paths["config/secrets"] << root.join("config", "secrets.yml").to_s
        end

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('KubeVirt Provider')
        end

        def self.init_loggers
          $kubevirt_log ||= Vmdb::Loggers.create_logger("kubevirt.log")
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $kubevirt_log, :level_kubevirt)
        end
      end
    end
  end
end
