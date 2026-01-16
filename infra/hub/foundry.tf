resource "azurerm_cognitive_account" "this" {
  name                       = "foundry-hub-${random_string.suffix.result}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.this.name
  kind                       = "AIServices"
  sku_name                   = "S0"
  project_management_enabled = true
  custom_subdomain_name      = "foundry-hub-${random_string.suffix.result}"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_account_project" "models_hub" {
  name                 = "models-hub"
  cognitive_account_id = azurerm_cognitive_account.this.id
  location             = var.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "gpt_4o_mini" {
  name                 = "gpt-4o-mini"
  cognitive_account_id = azurerm_cognitive_account.this.id
  rai_policy_name      = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  sku {
    name     = "DataZoneStandard"
    capacity = 100
  }
}
resource "azurerm_cognitive_deployment" "text_embedding_ada_002" {
  name                 = "text-embedding-ada-002"
  cognitive_account_id = azurerm_cognitive_account.this.id
  rai_policy_name      = "Microsoft.DefaultV2"

  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }

  sku {
    name     = "Standard"
    capacity = 20
  }
}

resource "azurerm_role_assignment" "currentuser_is_azureaiuser" {
  scope                = azurerm_cognitive_account.this.id
  role_definition_name = "Azure AI User"
  principal_id         = data.azurerm_client_config.current.object_id
}
