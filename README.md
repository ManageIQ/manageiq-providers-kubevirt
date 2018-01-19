# manageiq-providers-kubevirt

[![Gem Version](https://badge.fury.io/rb/manageiq-providers-kubevirt.svg)](http://badge.fury.io/rb/manageiq-providers-kubevirt)
[![Build Status](https://travis-ci.org/ManageIQ/manageiq-providers-kubevirt.svg)](https://travis-ci.org/ManageIQ/manageiq-providers-kubevirt)
[![Code Climate](https://codeclimate.com/github/ManageIQ/manageiq-providers-kubevirt.svg)](https://codeclimate.com/github/ManageIQ/manageiq-providers-kubevirt)
[![Test Coverage](https://codeclimate.com/github/ManageIQ/manageiq-providers-kubevirt/badges/coverage.svg)](https://codeclimate.com/github/ManageIQ/manageiq-providers-kubevirt/coverage)
[![Dependency Status](https://gemnasium.com/ManageIQ/manageiq-providers-kubevirt.svg)](https://gemnasium.com/ManageIQ/manageiq-providers-kubevirt)
[![Security](https://hakiri.io/github/ManageIQ/manageiq-providers-kubevirt/master.svg)](https://hakiri.io/github/ManageIQ/manageiq-providers-kubevirt/master)
[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/manageiq-providers-kubevirt?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Translate](https://img.shields.io/badge/translate-zanata-blue.svg)](https://translate.zanata.org/zanata/project/view/manageiq-providers-kubevirt)

Experimental [ManageIq](https://github.com/ManageIQ) provider which integrates [Kubevirt](https://github.com/kubevirt) project.

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

* In KubeVirt virtual machines are started when they are created. We are
discussing currnetly offline virtual machine which would represent stopped
vm. Offline virtual machine api is not implemented yet so we fake it by
defining [custom resource](manifests/crd-offline-virtual-machine.yml).

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
  # kubectl get secret default-token-7psxt -o yaml
  apiVersion: v1
  data:
    ca.crt: LS0...
  namespace: ZGV...
  token: ZXl...
  ...
  ```

The token is the value of the `token` attribute, but it is encoded using
base64, so it needs to be decoded:

  ```
  $ echo ZXl... | base64 -d
  eyJ...
  ```

The extracted value can now be used to authenticate with the Kubernetes
API, setting the `Authorization` header:

  ```
  Authorization: Bearer eyJ...
  ```
