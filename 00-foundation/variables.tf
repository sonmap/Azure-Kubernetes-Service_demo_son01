variable "location" {
  type        = string
  description = "Azure region"
  default     = "koreacentral"
}

variable "location_short" {
  type        = string
  description = "Short location code"
  default     = "krc"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
  default     = "aks-store-demo"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "tags" {
  type = map(string)
  default = {
    project     = "aks-store-demo"
    environment = "dev"
    owner       = "terraform"
  }
}
