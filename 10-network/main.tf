data "terraform_remote_state" "foundation" {
  backend = "local"
  config = {
    path = "../00-foundation/terraform.tfstate"
  }
}

locals {
  rg_name  = data.terraform_remote_state.foundation.outputs.resource_group_name
  location = data.terraform_remote_state.foundation.outputs.location
  tags     = data.terraform_remote_state.foundation.outputs.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-aks-store-demo-dev-krc"
  location            = local.location
  resource_group_name = local.rg_name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-snet-aks-store-demo-dev-krc"
  location            = local.location
  resource_group_name = local.rg_name
  tags                = local.tags
}

# Lab rule for Kubernetes Service type=LoadBalancer.
# Without this rule, the AKS Service can receive an EXTERNAL-IP but browser/curl access can time out
# when this subnet NSG is associated to the AKS subnet.
resource "azurerm_network_security_rule" "allow_public_lb_http" {
  count                       = var.enable_public_lb_access ? 1 : 0
  name                        = "tf-allow-aks-store-public-lb-http"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = var.public_lb_source_address_prefix
  destination_address_prefix  = "*"
  resource_group_name         = local.rg_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Explicitly allow Azure Load Balancer health probes.
# Azure has a default AllowAzureLoadBalancer rule, but this explicit rule makes the lab easier to read.
resource "azurerm_network_security_rule" "allow_azure_lb_probe" {
  count                       = var.enable_public_lb_access ? 1 : 0
  name                        = "tf-allow-azure-load-balancer-probe"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = local.rg_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Lab-only fallback for NodePort traffic. Kubernetes LoadBalancer Services allocate a NodePort
# in the 30000-32767 range. Keep this enabled for simple public tests, and disable for production.
resource "azurerm_network_security_rule" "allow_nodeport_test" {
  count                       = var.enable_nodeport_test_access ? 1 : 0
  name                        = "tf-allow-aks-nodeport-test"
  priority                    = 302
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "30000-32767"
  source_address_prefix       = var.public_lb_source_address_prefix
  destination_address_prefix  = "*"
  resource_group_name         = local.rg_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = local.rg_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.aks_subnet_prefixes
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}
