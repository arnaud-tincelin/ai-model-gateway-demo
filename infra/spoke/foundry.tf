resource "azurerm_cognitive_account" "this" {
  name                       = "foundry-spoke-${random_string.suffix.result}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  kind                       = "AIServices"
  sku_name                   = "S0"
  project_management_enabled = true
  custom_subdomain_name      = "foundry-spoke-${random_string.suffix.result}"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_account_project" "project" {
  name                 = "my-project"
  cognitive_account_id = azurerm_cognitive_account.this.id
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

// https://learn.microsoft.com/en-us/azure/ai-foundry/agents/how-to/ai-gateway?view=foundry
resource "azapi_resource" "model_gateway_connection" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = "model-gateway"
  parent_id = azurerm_cognitive_account_project.project.id
  body = {
    properties = {
      category      = "ApiManagement" # or "ModelGateway" if you are not using APIM
      target        = var.model_gateway.url
      authType      = "ApiKey"
      isSharedToAll = false
      credentials = {
        key = var.model_gateway.api_key
      }
      metadata = merge(
        {
          deploymentInPath    = tostring(var.model_gateway.metadata.deploymentInPath)
          inferenceAPIVersion = var.model_gateway.metadata.inferenceAPIVersion
          models              = jsonencode(var.model_gateway.metadata.models)
        },
        var.model_gateway.metadata.deploymentAPIVersion != null && var.model_gateway.metadata.deploymentAPIVersion != "" ? {
          deploymentAPIVersion = var.model_gateway.metadata.deploymentAPIVersion
        } : {}
      )
    }
  }
}

resource "azurerm_role_assignment" "currentuser_is_azureaiuser" {
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Azure AI User"
  principal_id         = data.azurerm_client_config.current.object_id
}
