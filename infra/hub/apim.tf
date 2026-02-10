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

resource "azurerm_api_management_logger" "appinsights" {
  name                = "appinsights-logger"
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  resource_id         = local.application_insights_id
  buffered            = false

  application_insights {
    connection_string = local.application_insights_connection_string
  }
}

# Azure Monitor logger for LLM logging
resource "azapi_resource" "apim_azuremonitor_logger" {
  type      = "Microsoft.ApiManagement/service/loggers@2024-06-01-preview"
  name      = "azuremonitor"
  parent_id = azurerm_api_management.this.id

  body = {
    properties = {
      loggerType = "azureMonitor"
      isBuffered = false
    }
  }
}

# API Diagnostic for Application Insights - for metrics and detailed logging
resource "azapi_resource" "api_diagnostic_appinsights" {
  type      = "Microsoft.ApiManagement/service/apis/diagnostics@2022-08-01"
  name      = "applicationinsights"
  parent_id = azurerm_api_management_api.azure_openai.id

  body = {
    properties = {
      alwaysLog               = "allErrors"
      httpCorrelationProtocol = "W3C"
      logClientIp             = true
      loggerId                = azurerm_api_management_logger.appinsights.id
      metrics                 = true
      verbosity               = "verbose"
      sampling = {
        samplingType = "fixed"
        percentage   = 100
      }
      frontend = {
        request = {
          headers = ["Content-type", "User-agent", "x-ms-region", "x-ratelimit-remaining-tokens", "x-ratelimit-remaining-requests"]
          body    = { bytes = 8192 }
        }
        response = {
          headers = ["Content-type", "User-agent", "x-ms-region", "x-ratelimit-remaining-tokens", "x-ratelimit-remaining-requests"]
          body    = { bytes = 8192 }
        }
      }
      backend = {
        request = {
          headers = ["Content-type", "User-agent", "x-ms-region", "x-ratelimit-remaining-tokens", "x-ratelimit-remaining-requests"]
          body    = { bytes = 8192 }
        }
        response = {
          headers = ["Content-type", "User-agent", "x-ms-region", "x-ratelimit-remaining-tokens", "x-ratelimit-remaining-requests"]
          body    = { bytes = 8192 }
        }
      }
    }
  }

  schema_validation_enabled = false
}

# Diagnostic Settings - Send APIM platform logs and metrics to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "apim" {
  name                           = "apimDiagnosticSettings"
  target_resource_id             = azurerm_api_management.this.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category_group = "AllLogs"
  }

  enabled_metric {
    category = "AllMetrics"
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

# =============================================================================
# APIM Products - Gold and Bronze tiers
# =============================================================================

# Gold Product - No restrictions, full access
resource "azurerm_api_management_product" "gold" {
  product_id            = "gold"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = azurerm_resource_group.this.name
  display_name          = "Gold"
  description           = "Gold tier - Unlimited access with no rate limiting"
  subscription_required = true
  approval_required     = false
  published             = true
}

# Bronze Product - Token rate limiting applied
resource "azurerm_api_management_product" "bronze" {
  product_id            = "bronze"
  api_management_name   = azurerm_api_management.this.name
  resource_group_name   = azurerm_resource_group.this.name
  display_name          = "Bronze"
  description           = "Bronze tier - Token rate limited access (1000 tokens per minute)"
  subscription_required = true
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product_api" "gold_openai" {
  api_name            = azurerm_api_management_api.azure_openai.name
  product_id          = azurerm_api_management_product.gold.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_api_management_product_api" "bronze_openai" {
  api_name            = azurerm_api_management_api.azure_openai.name
  product_id          = azurerm_api_management_product.bronze.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_api_management_subscription" "gold" {
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  product_id          = azurerm_api_management_product.gold.id
  display_name        = "Gold Subscription"
  state               = "active"
  allow_tracing       = true
}

resource "azurerm_api_management_subscription" "bronze" {
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  product_id          = azurerm_api_management_product.bronze.id
  display_name        = "Bronze Subscription"
  state               = "active"
  allow_tracing       = true
}

data "azapi_resource_action" "gold_subscription_keys" {
  type                   = "Microsoft.ApiManagement/service/subscriptions@2024-05-01"
  resource_id            = azurerm_api_management_subscription.gold.id
  action                 = "listSecrets"
  method                 = "POST"
  response_export_values = ["*"]
}

data "azapi_resource_action" "bronze_subscription_keys" {
  type                   = "Microsoft.ApiManagement/service/subscriptions@2024-05-01"
  resource_id            = azurerm_api_management_subscription.bronze.id
  action                 = "listSecrets"
  method                 = "POST"
  response_export_values = ["*"]
}

# =============================================================================
# Product Policies
# =============================================================================

# Gold product policy - No restrictions, just set backend
resource "azurerm_api_management_product_policy" "gold" {
  product_id          = azurerm_api_management_product.gold.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
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

# Bronze product policy - Token rate limiting (1000 tokens per minute)
resource "azurerm_api_management_product_policy" "bronze" {
  product_id          = azurerm_api_management_product.bronze.product_id
  api_management_name = azurerm_api_management.this.name
  resource_group_name = azurerm_resource_group.this.name
  xml_content         = <<XML
<policies>
  <inbound>
    <base />
    <llm-token-limit
      counter-key="@(context.Subscription.Id)"
      tokens-per-minute="1000"
      estimate-prompt-tokens="false"
      remaining-tokens-variable-name="remainingTokens">
    </llm-token-limit>
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
