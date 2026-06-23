data "terraform_remote_state" "foundation" {
  backend = "local"
  config = {
    path = "../00-foundation/terraform.tfstate"
  }
}

data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../10-network/terraform.tfstate"
  }
}

locals {
  rg_name  = data.terraform_remote_state.foundation.outputs.resource_group_name
  location = data.terraform_remote_state.foundation.outputs.location
  tags     = data.terraform_remote_state.foundation.outputs.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-store-demo-dev-krc"
  location            = local.location
  resource_group_name = local.rg_name
  dns_prefix          = "aks-store-demo-dev-krc"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  tags                = local.tags

  role_based_access_control_enabled = true
  local_account_disabled            = false

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.node_vm_size
    vnet_subnet_id = data.terraform_remote_state.network.outputs.aks_subnet_id
    os_sku         = "AzureLinux"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  oms_agent {
    log_analytics_workspace_id = data.terraform_remote_state.foundation.outputs.log_analytics_workspace_id
  }
}
