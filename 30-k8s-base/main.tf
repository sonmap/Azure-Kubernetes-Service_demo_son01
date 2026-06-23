resource "kubernetes_namespace_v1" "pets" {
  metadata {
    name = var.namespace
    labels = {
      app     = "aks-store-demo"
      managed = "terraform"
    }
  }
}
