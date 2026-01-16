resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "ai-model-gateway-demo"
  location = var.location
}

data "azurerm_client_config" "current" {}
