resource "helm_release" "istio_operator_crd" {
  name      = "istio-operator-crd"
  namespace = var.namespace

  chart = "${path.module}/config/istio-operator-crd"
}
