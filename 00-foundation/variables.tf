variable "location" {
  description = "Azure region"
  type        = string
  default     = "koreacentral"
}

variable "location_short" {
  description = "Short Azure region code"
  type        = string
  default     = "krc"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Common resource name prefix"
  type        = string
  default     = "aks-store-demo"
}

variable "log_analytics_sku" {
  description = "Log Analytics Workspace SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Log retention days"
  type        = number
  default     = 30
}
