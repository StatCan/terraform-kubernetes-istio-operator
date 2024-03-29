# Terraform Kubernetes Istio Operator

## Introduction

This module installs the Istio Operator v1.16.1. It attempts to replicate the installation via:

```bash
istioctl operator init
```

The ability to specify the **tag** of the image is available, however, this may cause issues since this
module uses the manifests of a specific version.

## Security Controls

The following security controls can be met through configuration of this template:

* TBD

## Requirements

* The namespace where Istio Operator is to be installed should already be created. (default istio-operator)
* Terraform v0.13+
* terraform-provider-kubernetes 2.4+
* terraform-provider-helm 2.0+

## Namespace Label Requirements

The namespace provided as the *namespace* variable requires the following labels:
* istio-operator-managed=Reconcile
* istio-injection=disabled

## Module Versioning

As of release v2.0.0, versioning will return to SEMVER so as to simplify releases.

## Optional (depending on options configured):

* None

## Usage

```terraform
module "istio_operator" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-istio-operator.git?ref=v2.6.0"

  # The following are variables that can be specified, but come with sane defaults
  namespace        = "istio-operator"
  watch_namespaces = ["istio-system"]
}
```

## Variables Values

| Name                       | Type         | Required | Default Value                    | Description                                                                                          |
| -------------------------- | ------------ | -------- | -------------------------------- | ---------------------------------------------------------------------------------------------------- |
| namespace                  | string       | no       | "istio-operator"                 | The namespace in which to install the Istio Operator.                                                |
| hub                        | string       | no       | "docker.io/istio"                | The hub where the image repositories are located.                                                    |
| node_selector              | map(string)  | no       | {}                               | `nodeSelector`s that should be added to the operators Pod.                                           |
| resources                  | object       | no       | see [variables.tf](variables.tf) | The resource requests and limits for the deployment.                                                 |
| tag                        | string       | no       | "1.16.1"                         | The tag of the image to use. WARNING: Use at own risk.                                               |
| wait_for_resources_timeout | number       | no       | 300                              | The amount of seconds that the operator should wait for a timeout.                                   |
| watch_namespaces           | list(string) | no       | ["istio-system"]                 | The namespaces that the Operator should watch for IstioOperator manifests. Empty for all Namespaces. |

## Updating Modules

### Migrating to v2+

There are 4 major changes in v2.0.0:
 - Labels on the namespace are no longer being set by the module (see [Namespace Label Requirements](#namespace-label-requirements))
 - Use of a Helm chart to deploy CRDs via `helm_release` resource instead of `kubectl` via the `null_resource`
    Note: the terraform-provider-kubernetes `kubernetes_manifest` was attempted to be used, however, in its current beta state
    it has difficulties reconciling resources and is still in beta.
 - Extracting the deployment of the **IstioOperator** manifest to allow for multiple IstioOperator configuration (important for Canary deployments)
 - Change of the `istio_namespace` variable to `watch_namespaces` for configurations that are more contextualized to the operator.
  This allows for the IstioOperator manifest to be deployed and actioned by the controller in these namespaces.

To ensure the successful upgrade , the following commands will need to be run:

```bash
module_name=istio_operator; # The label used for the module. Change based on your usage.
namespace=istio-operator; # Value entered as namespace in module < v2.0.0

# Labels are no longer being modified by the module
terraform state rm module.$module_name.null_resource.istio_operator_namespace_label;

# The IstioOperator manifest is no longer being deployed in this module.
# Please see: https://gitlab.k8s.cloud.statcan.ca/cloudnative/terraform/modules/terraform-kubernetes-istio-operator-instance
terraform state rm module.$module_name.null_resource.istio_operator;

# istio-operator Deployment can now be deployed with the provider due
# to fieldRefs being added.
terraform state rm module.$module_name.null_resource.istio_operator_controller

# Remove the installation of the CRD via null_resource
terraform state rm module.$module_name.null_resource.istio_operator_crd;

# Replace istio-operator namespace if not in default location
terraform import module.$module_name.kubernetes_deployment.istio_operator_controller $namespace/istio-operator;
```

## CRD Installation

There seem to be some regressions when it comes to the CRD that is installed via `istioctl`. Following is a table of
the CRD versions that are installed in each `istioctl` version:

| istioctl Version | CRD Version                                           |
| ---------------- | ----------------------------------------------------- |
| v1.6.14          | CustomResourceDefinition.apiextensions.k8s.io/v1beta1 |
| v1.7.8           | CustomResourceDefinition.apiextensions.k8s.io/v1      |
| v1.8.6           | CustomResourceDefinition.apiextensions.k8s.io/v1beta1 |
| v1.9.9           | CustomResourceDefinition.apiextensions.k8s.io/v1beta1 |
| v1.10.6          | CustomResourceDefinition.apiextensions.k8s.io/v1      |
| v1.16.1          | CustomResourceDefinition.apiextensions.k8s.io/v1      |

Note: the v1beta1 CRDs are missing the `type` parameter under **spec.validation.openAPIV3Schema** which causes some
validation issues with `kubernetes_manifest` resources.

To combat this, the v1 CRD has been backported to v2.0.0 to simplify installations.

## History

| Date     | Release     | Change                                                    |
| -------- | ----------- | --------------------------------------------------------- |
| 20200821 | v1.0.0      | 1st release                                               |
| 20210204 | v1.6.14     | Update to use the manifest dump of Istio Operator 1.6.14. |
| 20210824 | v1.0.1-tf13 | Align module to work with Terraform v0.13                 |
| 20210830 | v2.0.0      | Use new `kubernetes_manifest` resource from provider 2.4+ |
| -        | -           | Move out the installation of the IstioOperator manifest   |
| 20210831 | v2.1.0      | Update resources for Istio 1.7.8                          |
| 20211021 | v2.1.1      | Add ability to specify resources.                         |
| 20220225 | v2.2.0      | Add output of tag                                         |
| 20220511 | v2.3.0      | Add ability to set nodeSelectors.                         |
| 20220607 | v2.4.0      | Update resources for Istio 1.8.6                          |
| 20220628 | v2.5.0      | Update resources for Istio 1.10.6                         |
| 20220628 | v2.6.0      | Update resources for Istio 1.16.1                         |
