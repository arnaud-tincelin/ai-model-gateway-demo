resource "azurerm_api_management" "this" {
  name                = "model-gateway-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  publisher_name      = "contoso"
  publisher_email     = "user@contoso.com"
  sku_name            = "StandardV2_1"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "apim_can_use_cognitive_services" {
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Azure AI User"
  principal_id         = azurerm_api_management.this.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

data "azapi_resource_action" "master_keys" {
  type                   = "Microsoft.ApiManagement/service/subscriptions@2024-05-01"
  resource_id            = "${azurerm_api_management.this.id}/subscriptions/master"
  action                 = "listSecrets"
  method                 = "POST"
  response_export_values = ["*"]
}
