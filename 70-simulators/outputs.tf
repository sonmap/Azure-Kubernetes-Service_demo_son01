output "virtual_customer_deployment" {
  value = kubernetes_deployment_v1.virtual_customer.metadata[0].name
}

output "virtual_worker_deployment" {
  value = kubernetes_deployment_v1.virtual_worker.metadata[0].name
}
