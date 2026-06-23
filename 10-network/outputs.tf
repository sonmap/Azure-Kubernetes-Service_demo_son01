output "resource_group_name" {
  value = local.rg_name
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "aks_subnet_name" {
  value = azurerm_subnet.aks.name
}

output "aks_subnet_nsg_id" {
  value = azurerm_network_security_group.aks.id
}

output "aks_subnet_nsg_name" {
  value = azurerm_network_security_group.aks.name
}
