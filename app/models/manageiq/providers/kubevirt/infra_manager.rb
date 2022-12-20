class ManageIQ::Providers::Kubevirt::InfraManager < ManageIQ::Providers::InfraManager
  require_nested :Cluster
  require_nested :Connection
  require_nested :Host
  require_nested :Provision
  require_nested :ProvisionWorkflow
  require_nested :RefreshWorker
  require_nested :Refresher
  require_nested :Storage
  require_nested :Template
  require_nested :Vm

  ENDPOINT_ROLE = :kubevirt

  belongs_to :parent_manager,
             :foreign_key => :parent_ems_id,
             :class_name  => "ManageIQ::Providers::ContainerManager",
             :inverse_of  => :infra_manager

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
  supports :provisioning

  #
  # Returns the string that corresponds to this kind of provider.
  #
  # @return [String] The provider type.
  #
  def self.ems_type
    @ems_type ||= ManageIQ::Providers::Kubevirt::Constants::VENDOR
  end

  #
  # Returns the string that will be used to describe this provider.
  #
  # @return [String] The provider description.
  #
  def self.description
    @description ||= ManageIQ::Providers::Kubevirt::Constants::PRODUCT
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
    kubevirt&.valid? && kubevirt&.virt_supported?
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
    # Create the connection:
    Connection.new(
      :host      => opts[:server],
      :port      => opts[:port],
      :token     => ManageIQ::Password.try_decrypt(opts[:token]),
      :namespace => "" # Collect resources across all namespaces
    )
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
    with_provider_connection(opts, &:valid?)
  end

  #
  # Verifies that the provider responds to kubevirt resources in order to assure kubevirt is deployed
  # on top of the kubernetes cluster
  #
  # @param opts [Hash] Additional options to control how to perform the verification.
  #
  def verify_virt_supported(opts)
    virt_supported = with_provider_connection(opts, &:virt_supported?)
    raise "Kubevirt deployment was not found on provider" unless virt_supported
    virt_supported
  end

  def authentication_status_ok?(type = :kubevirt)
    authentication_best_fit(type).try(:status) == "Valid"
  end

  def authentication_for_providers
    authentications.where(:authtype => :kubevirt)
  end

  #
  # The ManageIQ core calls this method whenever a connection to the server is needed.
  #
  # @param opts [Hash] The options provided by the ManageIQ core.
  #
  def connect(opts = {})
    # Get the authentication token:
    token = opts[:token] || authentication_token(:kubevirt)

    # Create and return the connection:
    endpoint = default_endpoint
    self.class::Connection.new(
      :host      => endpoint.hostname,
      :port      => endpoint.port,
      :token     => token,
      :namespace => ""
    )
  end

  def virtualization_endpoint
    connection_configurations.kubevirt.try(:endpoint)
  end

  def default_authentication_type
    ENDPOINT_ROLE
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
