locals {
  inference_api_version = "2024-10-21"
}

resource "azurerm_api_management_api" "azure_openai" {
  name                = "azure-openai"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_api_management.this.resource_group_name
  revision            = "1"
  display_name        = "Azure OpenAI API"
  path                = "openai"
  protocols           = ["https"]

  import {
    content_format = "openapi-link"
    content_value  = "https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/${local.inference_api_version}/inference.json"
  }

  subscription_key_parameter_names {
    header = "api-key"
    query  = "api-key"
  }
}

# # Using azapi instead of azurerm_api_management_backend
# # because azurerm_api_management_backend does not support managed identity authentication
resource "azapi_resource" "azure_openai_backend" {
  type      = "Microsoft.ApiManagement/service/backends@2025-03-01-preview"
  name      = "lmpx-foundry-openai-backend"
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      protocol    = "http"
      url         = "${azurerm_cognitive_account.this.endpoint}openai"
      description = "LMPX Foundry Backend"
      credentials = {
        managedIdentity = {
          resource = "https://cognitiveservices.azure.com"
        }
      }
    }
  }
  schema_validation_enabled = false # because of block 'managedIdentity'
}

resource "azurerm_api_management_api_policy" "azure_openai" {
  api_name            = azurerm_api_management_api.azure_openai.name
  resource_group_name = azurerm_api_management.this.resource_group_name
  api_management_name = azurerm_api_management.this.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
    <set-backend-service backend-id="${azapi_resource.azure_openai_backend.name}" />
  </inbound>
  <backend>
    <base />
  </backend>
  <outbound>
    <base />
  </outbound>
  <on-error>
    <base />
  </on-error>
</policies>
XML
}
