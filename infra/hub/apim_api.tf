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
    <!-- Token Metrics Emitting - sends token usage metrics to Application Insights -->
    <azure-openai-emit-token-metric namespace="openai">
      <dimension name="Subscription ID" value="@(context.Subscription.Id)" />
      <dimension name="Product ID" value="@(context.Product.Id)" />
      <dimension name="Client IP" value="@(context.Request.IpAddress)" />
      <dimension name="API ID" value="@(context.Api.Id)" />
      <dimension name="User ID" value="@(context.Request.Headers.GetValueOrDefault("x-user-id", "N/A"))" />
    </azure-openai-emit-token-metric>
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

# API Diagnostic for Azure Monitor - with largeLanguageModel for LLM logging
resource "azapi_resource" "api_diagnostic_azuremonitor" {
  type      = "Microsoft.ApiManagement/service/apis/diagnostics@2024-06-01-preview"
  name      = "azuremonitor"
  parent_id = azurerm_api_management_api.azure_openai.id

  body = {
    properties = {
      alwaysLog   = "allErrors"
      verbosity   = "verbose"
      logClientIp = true
      loggerId    = azapi_resource.apim_azuremonitor_logger.id
      sampling = {
        samplingType = "fixed"
        percentage   = 100
      }
      frontend = {
        request = {
          headers = []
          body    = { bytes = 0 }
        }
        response = {
          headers = []
          body    = { bytes = 0 }
        }
      }
      backend = {
        request = {
          headers = []
          body    = { bytes = 0 }
        }
        response = {
          headers = []
          body    = { bytes = 0 }
        }
      }
      largeLanguageModel = {
        logs = "enabled"
        requests = {
          messages       = "all"
          maxSizeInBytes = 262144
        }
        responses = {
          messages       = "all"
          maxSizeInBytes = 262144
        }
      }
    }
  }

  schema_validation_enabled = false
}
