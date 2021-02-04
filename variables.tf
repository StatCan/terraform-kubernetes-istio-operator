variable "dependencies" {
  description = "The dependencies that this module has so that Terraform may build the dependency graph correctly."
  type        = "list"
}

variable "istio_namespace" {
  description = "The namespace where Istio should be installed."
  default     = "istio-system"
}

variable "hub" {
  description = "The hub where the image repository is located."
  default     = "docker.io/istio"
}

variable "namespace" {
  description = "The namespace in which to install the Istio Operator."
  default     = "istio-operator"
}

variable "tag" {
  description = "The image tag to use."
  default     = "1.6.14"
}

variable "iop_spec" {
  description = "The specification of the IstioOperator API."
  default     = ""
}