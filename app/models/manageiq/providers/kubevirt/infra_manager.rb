class ManageIQ::Providers::Kubevirt::InfraManager < ManageIQ::Providers::InfraManager
  DEFAULT_AUTH_TYPE = :kubevirt

  belongs_to :parent_manager,
             :foreign_key => :parent_ems_id,
             :class_name  => "ManageIQ::Providers::ContainerManager"

  delegate :authentication_check,
           :authentication_for_summary,
           :authentication_token,
           :authentications,
           :endpoints,
           :default_endpoint,
           :zone,
           :to        => :parent_manager,
           :allow_nil => true

  def self.hostname_required?
   false
  end

  #
  # This is the list of features that this provider supports:
  #
  supports :catalog
  supports :provisioning

  supports :metrics do
    _("No metrics endpoint has been added") unless metrics_endpoint_exists?
  end

  #
  # Returns the string that corresponds to this kind of provider.
  #
  # @return [String] The provider type.
  #
  def self.ems_type
    @ems_type ||= vendor
  end

  #
  # Returns the string that will be used to describe this provider.
  #
  # @return [String] The provider description.
  #
  def self.description
    @description ||= product_name
  end

  def self.vendor
    ManageIQ::Providers::Kubevirt::Constants::VENDOR
  end

  def self.product_name
    ManageIQ::Providers::Kubevirt::Constants::PRODUCT
  end

  def self.version
    ManageIQ::Providers::Kubevirt::Constants::VERSION
  end

  def self.catalog_types
    {"kubevirt" => N_("KubeVirt")}
  end

  def self.params_for_create
    {
      :title  => "Configure #{description}",
      :fields => [
        {
          :component  => "text-field",
          :name       => "endpoints.default.server",
          :label      => _("Hostname"),
          :isRequired => true,
          :validate   => [{:type => "required-validator"}]
        },
        {
          :component  => "text-field",
          :name       => "endpoints.default.port",
          :type       => "number",
          :isRequired => true,
          :validate   => [
            {
              :type => "required-validator"
            },
            {
              :type             => "validatorTypes.MIN_NUMBER_VALUE",
              :includeThreshold => true,
              :value            => 1
            },
            {
              :type             => "validatorTypes.MAX_NUMBER_VALUE",
              :includeThreshold => true,
              :value            => 65_535
            }
          ]
        },
        {
          :component  => "text-field",
          :name       => "endpoints.default.token",
          :label      => _("Token"),
          :type       => "password",
          :isRequired => true,
          :validate   => [{:type => "required-validator"}]
        }
      ]
    }.freeze
  end

  def self.verify_credentials(args)
    kubevirt = raw_connect(args.dig("endpoints", "default")&.slice("server", "port", "token")&.symbolize_keys)
    kubevirt&.get_api_group_list
    kubevirt&.get_api_group_kubevirt_io
  end

  #
  # This method from the dialog that adds a provider, to verify the connection details and the
  # credentials.
  #
  # @param options [Hash] The connection options.
  # @option opts [String] :server The Kubernetes API server host name or IP address.
  # @option opts [Integer] :port The Kubernetes API port number.
  # @option opts [String] :token The Kubernetes authentication token.
  #
  def self.raw_connect(opts)
    require "kubevirt"

    api_key = ManageIQ::Password.try_decrypt(opts[:token])

    kubevirt_api_client = Kubevirt::ApiClient.new
    kubevirt_api_client.config.api_key    = api_key
    kubevirt_api_client.config.scheme     = "https"
    kubevirt_api_client.config.host       = "#{opts[:server]}:#{opts[:port] || 6443}"
    kubevirt_api_client.config.verify_ssl = false # TODO check security_protocol
    kubevirt_api_client.config.logger     = $kubevirt_log
    kubevirt_api_client.config.debugging  = Settings.log.level == "debug"
    kubevirt_api_client.default_headers["Authorization"] = "Bearer #{api_key}"

    Kubevirt::DefaultApi.new(kubevirt_api_client)
  end

  #
  # This method needs to be overriden because by default the ManageIQ core assumes that the user name is
  # mandatory, but it in KubeVirt it isn't, as we can use a token or a client certificate.
  #
  # @param type [String] The authentication scope, for example `default` or `metrics`.
  # @return [Boolean] `true` If credentials have been provided, `false` otherwise.
  #
  def has_credentials?(_type = nil)
    true
  end

  #
  # Verifies that the provided credentials are valid for this provider. In this provider that means
  # trying to connect to the KubeVirt API using the credentials.
  #
  # @param type [String] The authentication scope, for example `default` or `metrics`.
  # @param opts [Hash] Additional options to control how to perform the verification.
  #
  def verify_credentials(_type = nil, opts = {})
    with_provider_connection(opts) do |kubevirt|
      # First check that we're able to connect to the k8s API
      kubevirt.get_api_group_list
      # Then check that we can access the /apis/kubevirt.io API group
      kubevirt.get_api_group_kubevirt_io
    rescue Kubevirt::ApiError => err
      raise MiqException::MiqInvalidCredentialsError, N_("Unauthorized") if err.code == 401
      raise MiqException::MiqUnreachableError,        N_("Unreachable")  if err.code == 0
      raise MiqException::MiqUnreachableError,        N_("Virtualization not enabled") if err.code == 404
      raise
    end
  end

  #
  # Verifies that the provider responds to kubevirt resources in order to assure kubevirt is deployed
  # on top of the kubernetes cluster
  #
  # @param opts [Hash] Additional options to control how to perform the verification.
  #
  alias verify_virt_supported verify_credentials

  def authentication_status(type = default_authentication_type)
    authentication_best_fit(type).try(:status)
  end

  def authentication_status_ok?(type = default_authentication_type)
    authentication_status(type) == "Valid"
  end

  def authentication_for_providers
    authentications.where(:authtype => default_authentication_type)
  end

  #
  # The ManageIQ core calls this method whenever a connection to the server is needed.
  #
  # @param opts [Hash] The options provided by the ManageIQ core.
  #
  def connect(opts = {})
    # Get the authentication token:
    token = opts[:token] || authentication_token(default_authentication_type)

    self.class.raw_connect(:server => default_endpoint.hostname, :port => default_endpoint.port, :token => token)
  end

  def virtualization_endpoint
    connection_configurations.kubevirt.try(:endpoint)
  end

  def metrics_endpoint_exists?
    endpoints.where(:role => "prometheus").exists?
  end

  def default_authentication_type
    DEFAULT_AUTH_TYPE
  end

  #
  # This method will be called by the ManageIQ core when it needs to do a full refresh of the
  # inventory data.
  #
  # @return [Class] The class that implements the full refresh process for this provider.
  #
  def refresher
    self.class::Refresher
  end

  #
  # This method will be called by the ManageIQ core when it needs to do provisioning.
  #
  # @param via [String] The kind of provisioning that should be performed. It will be `iso` for
  #   provisioning from an ISO image, `pxe` for provisioning using PXE.
  #
  # @return [Class] The class that implements the provisioning.
  #
  def self.provision_class(_via)
    self::Provision
  end

  def self.display_name(number = 1)
    n_('Infrastructure Provider (Kubevirt)', 'Infrastructure Providers (Kubevirt)', number)
  end
end
