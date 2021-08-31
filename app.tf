resource "kubernetes_service" "istio_operator_service" {
  metadata {
    name = "istio-operator"
    labels = {
      name = "istio-operator"
    }
    namespace = var.namespace
  }

  spec {
    selector = {
      name = "istio-operator"
    }

    port {
      name        = "http-metrics"
      port        = 8383
      target_port = 8383
    }
  }
}

resource "kubernetes_deployment" "istio_operator_controller" {
  metadata {
    name      = "istio-operator"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        name = "istio-operator"
      }
    }

    template {
      metadata {
        labels = {
          name = "istio-operator"
        }
      }

      spec {
        service_account_name = "istio-operator"

        container {
          name              = "istio-operator"
          image             = "${var.hub}/operator:${var.tag}"
          image_pull_policy = "IfNotPresent"

          command = ["operator", "server"]

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }

            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
          }

          env {
            name  = "WATCH_NAMESPACE"
            value = join(",", var.watch_namespaces)
          }

          env {
            name = "LEADER_ELECTION_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name  = "OPERATOR_NAME"
            value = "istio-operator"
          }
        }
      }
    }
  }
}
