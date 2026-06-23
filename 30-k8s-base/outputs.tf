output "namespace" {
  value = kubernetes_namespace_v1.pets.metadata[0].name
}
