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

# =============================================================================
# Log Analytics and Application Insights for Token Metrics
# =============================================================================

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-analytics-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights with CustomMetricsOptedInType enabled for token metrics
# Using azapi_resource because azurerm_application_insights doesn't support CustomMetricsOptedInType
resource "azapi_resource" "application_insights" {
  type      = "Microsoft.Insights/components@2020-02-02"
  name      = "appi-model-gateway-${random_string.suffix.result}"
  location  = var.location
  parent_id = azurerm_resource_group.this.id

  # Disable schema validation - CustomMetricsOptedInType is valid but not in azapi schema yet
  schema_validation_enabled = false

  body = {
    kind = "web"
    properties = {
      Application_Type = "web"
      WorkspaceResourceId = azurerm_log_analytics_workspace.this.id
      # Required for azure-openai-emit-token-metric policy to emit metrics with dimensions
      CustomMetricsOptedInType = "WithDimensions"
    }
  }

  response_export_values = ["properties.InstrumentationKey", "properties.ConnectionString"]
}

# Create a local reference for easier access
locals {
  application_insights_id                = azapi_resource.application_insights.id
  application_insights_instrumentation_key = azapi_resource.application_insights.output.properties.InstrumentationKey
  application_insights_connection_string   = azapi_resource.application_insights.output.properties.ConnectionString
}
