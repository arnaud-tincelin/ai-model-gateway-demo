output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "apim_subscription_key" {
  value     = data.azapi_resource_action.master_keys.output.primaryKey
  sensitive = true
}

output "apim_gateway_url" {
  value = azurerm_api_management.this.gateway_url
}

output "azure_openai_endpoint" {
  value = "${azurerm_api_management.this.gateway_url}/${azurerm_api_management_api.azure_openai.path}"
}

output "gold_subscription_key" {
  description = "API key for Gold product subscription (no rate limiting)"
  value       = data.azapi_resource_action.gold_subscription_keys.output.primaryKey
  sensitive   = true
}

output "bronze_subscription_key" {
  description = "API key for Bronze product subscription (token rate limited)"
  value       = data.azapi_resource_action.bronze_subscription_keys.output.primaryKey
  sensitive   = true
}

locals {
  model_deployments = [
    azurerm_cognitive_deployment.gpt_4o_mini,
    azurerm_cognitive_deployment.text_embedding_ada_002
  ]
}

output "model_gateway_metadata" {
  value = {
    deploymentInPath     = true
    inferenceAPIVersion  = local.inference_api_version
    models = [
      for deployment in local.model_deployments : {
        name = deployment.name
        properties = {
          model = {
            name    = deployment.model[0].name
            version = deployment.model[0].version
            format  = deployment.model[0].format
          }
        }
      }
    ]
  }
}
