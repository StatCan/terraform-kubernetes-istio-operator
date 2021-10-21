variable "watch_namespaces" {
  description = "The namespaces that the Operator should watch for IstioOperator manifests. Empty for all Namespaces."
  type        = list(string)
  default     = ["istio-system"]
}

variable "wait_for_resources_timeout" {
  description = "The amount of seconds that the operator should wait for a timeout."
  type        = number
  default     = 300
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
  default     = "1.7.8"
}

variable "resources" {
  description = "The resource requests and limits for the deployment."
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })

  default = {
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "128Mi"
    }
  }
}
