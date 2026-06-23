variable "namespace" {
  type    = string
  default = "pets"
}

variable "enable_ai_service" {
  type    = bool
  default = false
}

variable "image_registry" {
  type    = string
  default = "ghcr.io/azure-samples/aks-store-demo"
}

variable "image_tag" {
  type    = string
  default = "2.1.0"
}

variable "use_azure_openai" {
  type    = string
  default = "True"
}

variable "azure_openai_deployment_name" {
  type    = string
  default = ""
}

variable "azure_openai_endpoint" {
  type    = string
  default = ""
}

variable "openai_api_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "openai_org_id" {
  type    = string
  default = ""
}
