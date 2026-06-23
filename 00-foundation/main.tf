locals {
  name_suffix = "${var.environment}-${var.location_short}"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.prefix}-${local.name_suffix}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${var.prefix}-${local.name_suffix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}
