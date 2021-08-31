terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=>2.0.0"
    }
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.13"
}
