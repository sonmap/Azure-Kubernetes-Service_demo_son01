variable "kubernetes_version" {
  type        = string
  description = "AKS Kubernetes version. Empty means Azure default."
  default     = null
}

variable "node_count" {
  type        = number
  description = "System node pool count"
  default     = 1
}

variable "node_vm_size" {
  type        = string
  description = "AKS node VM size"
  default     = "Standard_D2s_v3"
}

variable "service_cidr" {
  type    = string
  default = "10.41.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "10.41.0.10"
}
