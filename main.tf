# Part of a hack for module-to-module dependencies.
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
# and
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-473091030
# Make sure to add this null_resource.dependency_getter to the `depends_on`
# attribute to all resource(s) that will be constructed first within this
# module:
resource "null_resource" "dependency_getter" {
  triggers = {
    my_dependencies = "${join(",", var.dependencies)}"
  }

  lifecycle {
    ignore_changes = [
      triggers["my_dependencies"],
    ]
  }
}

# Unable to use kubernetes provider for CRDs
# This will be rectified once we are on 1.17 and the kubernetes provider is officially updated 
# https://www.hashicorp.com/blog/deploy-any-resource-with-the-new-kubernetes-provider-for-hashicorp-terraform/
resource "null_resource" "istio_operator_namespace_label" {
  triggers = {
    namespace = var.namespace
  }

  provisioner "local-exec" {
    command = "kubectl label ns ${var.namespace} istio-operator-managed=Reconcile istio-injection=disabled --overwrite"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl label ns ${self.triggers.namespace} istio-operator-managed- istio-injection-"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "null_resource" "istio_operator_crd" {
  triggers = {
    hash_istio_operator_crd = filesha256("${path.module}/config/iop-crd.yaml"),
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${"${path.module}/config/iop-crd.yaml"}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete crd istiooperators.install.istio.io"
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
}


resource "kubernetes_service_account" "istio_operator_service_account" {
  metadata {
    name      = "istio-operator"
    namespace = var.namespace
  }

  automount_service_account_token = true

  depends_on = [
    "null_resource.dependency_getter",
  ]
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
    api_groups = ["rbac.istio.io"]
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
    verbs      = ["get", "create"]
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
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "events", "namespaces", "pods", "persistentvolumeclaims", "secrets", "services", "serviceaccounts"]
    verbs      = ["*"]
  }

  depends_on = [
    "null_resource.dependency_getter",
  ]
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
    "null_resource.dependency_getter",
    "kubernetes_cluster_role.istio_operator_cluster_role",
  ]
}

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

  depends_on = [
    "null_resource.dependency_getter",
  ]
}

resource "local_file" "istio_operator_deployment" {
  content = templatefile("${path.module}/config/iop-deployment.yaml", {
    istio_namespace = var.istio_namespace
    hub             = var.hub
    tag             = var.tag
  })

  filename = "${path.module}/iop-deployment.yaml"
}

# Unable to use the kubernetes provider deployement due to the need for 
# the Downward API in the environment variables.
# This will be rectified once we are on 1.17 and the kubernetes provider is officially updated 
# https://www.hashicorp.com/blog/deploy-any-resource-with-the-new-kubernetes-provider-for-hashicorp-terraform/
resource "null_resource" "istio_operator_deployment" {
  triggers = {
    hash_istio_operator_deployment = sha256(local_file.istio_operator_deployment.content),
    namespace                      = var.namespace
  }

  provisioner "local-exec" {
    command = "kubectl -n ${var.namespace} apply -f ${local_file.istio_operator_deployment.filename}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl -n ${self.triggers.namespace} delete deployment istio-operator"
  }

  depends_on = [
    "null_resource.dependency_getter",
    "kubernetes_service_account.istio_operator_service_account",
    "local_file.istio_operator_deployment",
  ]
}

# Part of a hack for module-to-module dependencies.
# https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
resource "null_resource" "dependency_setter" {
  # Part of a hack for module-to-module dependencies.
  # https://github.com/hashicorp/terraform/issues/1178#issuecomment-449158607
  # List resource(s) that will be constructed last within the module.
  depends_on = [
    "null_resource.istio_operator_crd",
    "kubernetes_service_account.istio_operator_service_account",
    "kubernetes_cluster_role.istio_operator_cluster_role",
    "kubernetes_cluster_role_binding.istio_operator_cluster_role_binding",
    "kubernetes_service.istio_operator_service",
    "null_resource.istio_operator_deployment",
  ]
}
