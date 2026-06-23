output "mongodb_service_name" {
  value = kubernetes_service_v1.mongodb.metadata[0].name
}

output "rabbitmq_service_name" {
  value = kubernetes_service_v1.rabbitmq.metadata[0].name
}
