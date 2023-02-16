# ManageIQ::Providers::Kubevirt

[![CI](https://github.com/ManageIQ/manageiq-providers-kubevirt/actions/workflows/ci.yaml/badge.svg?branch=petrosian)](https://github.com/ManageIQ/manageiq-providers-kubevirt/actions/workflows/ci.yaml)
[![Maintainability](https://api.codeclimate.com/v1/badges/164d3344f7d1a833e6ef/maintainability)](https://codeclimate.com/github/ManageIQ/manageiq-providers-kubevirt/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/164d3344f7d1a833e6ef/test_coverage)](https://codeclimate.com/github/ManageIQ/manageiq-providers-kubevirt/test_coverage)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq-providers-kubevirt?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build history for petrosian branch](https://buildstats.info/github/chart/ManageIQ/manageiq-providers-kubevirt?branch=petrosian&buildCount=50&includeBuildsFromPullRequest=false&showstats=false)](https://github.com/ManageIQ/manageiq-providers-kubevirt/actions?query=branch%3Amaster)

ManageIQ plugin for the KubeVirt provider.

## Things that work

Currently the provider supports the following simple use cases:

1. Add the provider using token authentication.

2. Clone virtual machines from templates.

3. Connect to the SPICE console of the virtual machines.

4. Virtual machine power management: stop and start

## Things that don't work

* The Kubernetes API suports authentication using client side digital
certificates, tokens and user name and passwords. The KubeVirt provider only
supports tokens. The UI already has the posibility to specify other
authentication mechanisms, but they don't work in the provider side yet.

* The use of client certificates should probably be part of the ManageIQ
core, as many other providers may want to support them. For example,
oVirt could use them in combination with an authentication configuration
that uses the client certificate subject as the user name.

* The UI works for initial validation and credentials, and for adding the
provider, but it doesn't work for editing the provider: it doesn't show the
selected authentication method, and it doesn't show the token.

## Things that should be changed

* Kubernetes has a `namespace` concept that is currently ignored by the
provider, it only uses the `default` namespace, and that is hard-coded.
We should consider making the namespace part of the initial dialog to
add the provider, like the authentication details or the IP address.

* In KubeVirt virtual machine instances are started when they are created.
Virtual machine represent stopped vm.

* The provider considers the KubeVirt configuration the source of truth. 
That should be changed, the source of truth should be the ManageIQ database.

* There is no event tracker. The refresh of the inventory is only performed
manually, or when a new virtual machine is added.

* The inventory refresh uses the _graph refresh_ mechanism, but it
always performs a full refresh, there are no specific targers (like
virtual machines, or hosts) implemented yet.

* The `kubeclient` gem that the provider uses to talk to the Kubernetes API
doesn't support the sub-resource mechanism used by the KubeVirt API for SPICE
details. In addition Kubernetes itself doesn't yet support sub-resources
for custom resource definitions. As a result the provider has to extract
the SPICE proxy URL from the configuration of the `spice-proxy` service.

## Notes

### How to get the default token from Kubernetes

List the set of secrets:

  ```
  $ kubectl get secrets
  NAME                  TYPE                                  DATA      AGE
  default-token-7psxt   kubernetes.io/service-account-token   3         20d
  ```

Get the details of the `default` token:

  ```
  # kubectl describe secret default-token-7psxt
  Name:         default-token-7psxt
  Namespace:    default
  Labels:       <none>
  Annotations:  kubernetes.io/service-account.name=default
                kubernetes.io/service-account.uid=d748bdb5-f9dc-11e7-9332-525400d6a390

  Type:  kubernetes.io/service-account-token

  Data
  ====
  ca.crt:     1025 bytes
  namespace:  7 bytes
  token:      eyJhbGciO...
  ...
  ```

The token is the value of the `token` attribute.

The extracted value can now be used to authenticate with the Kubernetes API, setting the `Authorization` header:

  ```
  Authorization: Bearer eyJ...
  ```

## Development

See the section on plugins in the [ManageIQ Developer Setup](http://manageiq.org/docs/guides/developer_setup/plugins)

For quick local setup run `bin/setup`, which will clone the core ManageIQ repository under the *spec* directory and setup necessary config files. If you have already cloned it, you can run `bin/update` to bring the core ManageIQ code up to date.

## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
