variable "vnet_address_space" {
  type    = list(string)
  default = ["10.40.0.0/16"]
}

variable "aks_subnet_prefixes" {
  type    = list(string)
  default = ["10.40.1.0/24"]
}

variable "enable_public_lb_access" {
  type        = bool
  description = "Lab option. Allow Internet access to Kubernetes LoadBalancer services through the AKS subnet NSG. Set false for private/production style tests."
  default     = true
}

variable "enable_nodeport_test_access" {
  type        = bool
  description = "Lab option. Allow Kubernetes NodePort range from Internet. This prevents timeout when Azure LoadBalancer traffic is evaluated against the subnet NSG. Disable for production."
  default     = true
}

variable "public_lb_source_address_prefix" {
  type        = string
  description = "Source prefix allowed to access public LoadBalancer services. Use your public IP/CIDR instead of Internet for safer tests."
  default     = "Internet"
}
