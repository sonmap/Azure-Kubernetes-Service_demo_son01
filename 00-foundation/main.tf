locals {
  resource_group_name = "rg-${var.name_prefix}-${var.environment}-${var.location_short}"
  log_analytics_name  = "log-${var.name_prefix}-${var.environment}-${var.location_short}"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.log_analytics_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
}
