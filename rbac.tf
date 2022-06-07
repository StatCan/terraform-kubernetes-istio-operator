resource "kubernetes_service_account" "istio_operator_service_account" {
  metadata {
    name      = "istio-operator"
    namespace = var.namespace
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "istio_operator_cluster_role" {
  metadata {
    name = "istio-operator"
  }

  # istio groups
  rule {
    api_groups = ["authentication.istio.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["config.istio.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["install.istio.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["networking.istio.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["security.istio.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  # k8s groups
  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions.apiextensions.k8s.io", "customresourcedefinitions"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["apps", "extensions"]
    resources  = ["daemonsets", "deployments", "deployments/finalizers", "ingresses", "replicasets", "statefulsets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["monitoring.coreos.com"]
    resources  = ["servicemonitors"]
    verbs      = ["get", "create", "update"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterrolebindings", "clusterroles", "roles", "rolebindings"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "create", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "events", "namespaces", "pods", "pod/proxy", "persistentvolumeclaims", "secrets", "services", "serviceaccounts"]
    verbs      = ["*"]
  }
}


resource "kubernetes_cluster_role_binding" "istio_operator_cluster_role_binding" {
  metadata {
    name = "istio-operator"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "istio-operator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "istio-operator"
    namespace = var.namespace
  }

  depends_on = [
    kubernetes_cluster_role.istio_operator_cluster_role,
  ]
}
