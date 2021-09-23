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
        service_account_name = kubernetes_service_account.istio_operator_service_account.metadata[0].name

        container {
          name              = "istio-operator"
          image             = "${var.hub}/operator:${var.tag}"
          image_pull_policy = "IfNotPresent"

          command = ["operator", "server"]

          security_context {
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
            }
            privileged                = false
            read_only_root_filesystem = true
            run_as_group              = 1337
            run_as_user               = 1337
            run_as_non_root           = true
          }

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

          env {
            name  = "WAIT_FOR_RESOURCES_TIMEOUT"
            value = "${floor(var.wait_for_resources_timeout)}s"
          }

          env {
            name  = "REVISION"
            value = ""
          }
        }
      }
    }
  }
}
