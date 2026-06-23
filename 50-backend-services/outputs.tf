output "order_service_name" {
  value = kubernetes_service_v1.order_service.metadata[0].name
}

output "makeline_service_name" {
  value = kubernetes_service_v1.makeline_service.metadata[0].name
}

output "product_service_name" {
  value = kubernetes_service_v1.product_service.metadata[0].name
}
