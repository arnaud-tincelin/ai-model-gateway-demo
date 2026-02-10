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

# Gold tier connection - No rate limiting
resource "azapi_resource" "model_gateway_connection_gold" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = "model-gateway-gold"
  parent_id = azurerm_cognitive_account_project.project.id
  body = {
    properties = {
      category      = "ApiManagement"
      target        = var.model_gateway_gold.url
      authType      = "ApiKey"
      isSharedToAll = false
      credentials = {
        key = var.model_gateway_gold.api_key
      }
      metadata = merge(
        {
          deploymentInPath    = tostring(var.model_gateway_gold.metadata.deploymentInPath)
          inferenceAPIVersion = var.model_gateway_gold.metadata.inferenceAPIVersion
          models              = jsonencode(var.model_gateway_gold.metadata.models)
        },
        var.model_gateway_gold.metadata.deploymentAPIVersion != null && var.model_gateway_gold.metadata.deploymentAPIVersion != "" ? {
          deploymentAPIVersion = var.model_gateway_gold.metadata.deploymentAPIVersion
        } : {}
      )
    }
  }
}

# Bronze tier connection - Token rate limited (1000 tokens per minute)
resource "azapi_resource" "model_gateway_connection_bronze" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name      = "model-gateway-bronze"
  parent_id = azurerm_cognitive_account_project.project.id
  body = {
    properties = {
      category      = "ApiManagement"
      target        = var.model_gateway_bronze.url
      authType      = "ApiKey"
      isSharedToAll = false
      credentials = {
        key = var.model_gateway_bronze.api_key
      }
      metadata = merge(
        {
          deploymentInPath    = tostring(var.model_gateway_bronze.metadata.deploymentInPath)
          inferenceAPIVersion = var.model_gateway_bronze.metadata.inferenceAPIVersion
          models              = jsonencode(var.model_gateway_bronze.metadata.models)
        },
        var.model_gateway_bronze.metadata.deploymentAPIVersion != null && var.model_gateway_bronze.metadata.deploymentAPIVersion != "" ? {
          deploymentAPIVersion = var.model_gateway_bronze.metadata.deploymentAPIVersion
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
