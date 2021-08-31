variable "watch_namespaces" {
  description = "The namespaces that the Operator should watch for IstioOperator manifests. Empty for all Namespaces."
  type        = list(string)
  default     = ["istio-system"]
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
