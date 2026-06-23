variable "namespace" {
  type    = string
  default = "pets"
}

variable "image_registry" {
  type    = string
  default = "ghcr.io/azure-samples/aks-store-demo"
}

variable "image_tag" {
  type    = string
  default = "2.1.0"
}

variable "orders_per_hour" {
  type    = string
  default = "100"
}
