# Terraform Kubernetes Istio Operator

## Introduction

This module installs the Istio Operator. It attempts to replicate the installation via: 

```bash
istioctl operator init
```

This module also deploys a manifest for IstioOperator which is used to deploy the Istio control plane. 
It can be modified by specifiying yaml that aligns with the [IstioOperator API](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/)
in the **iop_spec** variable.

## Security Controls

The following security controls can be met through configuration of this template:

* TBD

## Dependencies

* The namespace where Istio Operator is to be installed should already be created. (default istio-operator)

## Information
This module will label the namespace provided as the *namespace* variable with the following labels:
* istio-operator-managed=Reconcile
* istio-injection=disabled

These labels will be removed when the module is destroyed.

## Module Versioning
As of release 1.6.14, the modules will align with the version of the Istio Operator they are installing.

## Optional (depending on options configured):

* None

## Usage

```terraform
module "istio_operator" {
  source = "git::https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-kubernetes-istio-operator?ref=v1.6.14"

  dependencies  = [
    module.namespace_cert_manager.depended_on,
  ]

  # The following are variables that can be specified, but come with sane defaults
  namespace       = "istio-operator"
  istio_namespace = "istio-system"
  hub             = "docker.io/istio"
  tag             = "1.6.14"

  iop_spec = <<EOF
addonComponents:
  ...
components:
  ...
values:
  ...
EOF
}
```

## Variables Values

| Name            | Type            | Required | Default Value   | Description                                                    |
| --------------- | --------------- | -------- | --------------- | -------------------------------------------------------------- |
| namespace       | string          | no       | istio-operator  | The namespace in which to install the Istio Operator.          |
| dependencies    | list of strings | no       |                 | The Terraform dependencies to be used by the module.           |
| hub             | string          | no       | docker.io/istio | The hub where the image repositories are located.              |
| tag             | string          | no       | 1.6.14          | The tag of the version of the Istio Operator to install.       |
| istio_namespace | string          | no       | istio-system    | The namespace where the Istio control plane will be installed. |
| iop_spec        | string          | no       | ""              | The specification for the IstioOperator API.                   |

## History

| Date     | Release | Change                                                    |
| -------- | ------- | --------------------------------------------------------- |
| 20200821 | v1.0.0  | 1st release                                               |
| 20210204 | v1.6.14 | Update to use the manifest dump of Istio Operator 1.6.14. |
