variable "namespace" {
  type    = string
  default = "pets"
}

variable "rabbitmq_username" {
  type      = string
  default   = "username"
  sensitive = true
}

variable "rabbitmq_password" {
  type      = string
  default   = "password"
  sensitive = true
}
