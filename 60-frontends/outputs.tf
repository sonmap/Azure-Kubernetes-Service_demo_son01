output "store_front_external_ip" {
  value       = try(kubernetes_service_v1.store_front.status[0].load_balancer[0].ingress[0].ip, null)
  description = "Public IP address for store-front."
}

output "store_front_url" {
  value       = try("http://${kubernetes_service_v1.store_front.status[0].load_balancer[0].ingress[0].ip}", null)
  description = "Browser URL for store-front."
}

output "store_front_node_port" {
  value       = try(kubernetes_service_v1.store_front.spec[0].port[0].node_port, null)
  description = "NodePort allocated by Kubernetes for store-front."
}

output "store_admin_external_ip" {
  value       = try(kubernetes_service_v1.store_admin.status[0].load_balancer[0].ingress[0].ip, null)
  description = "Public IP address for store-admin."
}

output "store_admin_url" {
  value       = try("http://${kubernetes_service_v1.store_admin.status[0].load_balancer[0].ingress[0].ip}", null)
  description = "Browser URL for store-admin."
}

output "store_admin_node_port" {
  value       = try(kubernetes_service_v1.store_admin.spec[0].port[0].node_port, null)
  description = "NodePort allocated by Kubernetes for store-admin."
}
