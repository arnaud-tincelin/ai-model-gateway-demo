# Dynamic discovery operations (commented out - not needed with static models)
# Uncomment if switching back to dynamic model discovery

# resource "azurerm_api_management_api_operation" "list_deployments" {
#   operation_id        = "list-deployments"
#   api_name            = azurerm_api_management_api.azure_openai.name
#   api_management_name = azurerm_api_management.this.name
#   resource_group_name = azurerm_api_management.this.resource_group_name
#   display_name        = "List Deployments"
#   method              = "GET"
#   url_template        = "/deployments"
#   description         = "Lists all model deployments available"
# }

# resource "azurerm_api_management_api_operation_policy" "list_deployments" {
#   api_name            = azurerm_api_management_api.azure_openai.name
#   api_management_name = azurerm_api_management.this.name
#   resource_group_name = azurerm_api_management.this.resource_group_name
#   operation_id        = azurerm_api_management_api_operation.list_deployments.operation_id

#   xml_content = <<XML
# <policies>
#   <inbound>
#     # <authentication-managed-identity resource="https://management.azure.com/" />
#     <rewrite-uri template="/deployments?api-version=2023-05-01" copy-unmatched-params="false" />
#     <set-backend-service base-url="https://management.azure.com/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.this.name}/providers/Microsoft.CognitiveServices/accounts/${jsondecode(azurerm_resource_group_template_deployment.ai_foundry.output_content).foundryAccountName.value}" />
#   </inbound>
#   <backend>
#     <base />
#   </backend>
#   <outbound>
#     <base />
#   </outbound>
#   <on-error>
#     <base />
#   </on-error>
# </policies>
# XML
# }

# resource "azurerm_api_management_api_operation" "get_deployment" {
#   operation_id        = "get-deployment-by-name"
#   api_name            = azurerm_api_management_api.azure_openai.name
#   api_management_name = azurerm_api_management.this.name
#   resource_group_name = azurerm_api_management.this.resource_group_name
#   display_name        = "Get Deployment By Name"
#   method              = "GET"
#   url_template        = "/deployments/{deploymentName}"
#   description         = "Gets details for a specific model deployment"

#   template_parameter {
#     name     = "deploymentName"
#     type     = "string"
#     required = true
#   }
# }

# resource "azurerm_api_management_api_operation_policy" "get_deployment" {
#   api_name            = azurerm_api_management_api.azure_openai.name
#   api_management_name = azurerm_api_management.this.name
#   resource_group_name = azurerm_api_management.this.resource_group_name
#   operation_id        = azurerm_api_management_api_operation.get_deployment.operation_id

#   xml_content = <<XML
# <policies>
#   <inbound>
#     # <authentication-managed-identity resource="https://management.azure.com/" />
#     <rewrite-uri template="/deployments/{deploymentName}?api-version=2023-05-01" copy-unmatched-params="false" />
#     <set-backend-service base-url="https://management.azure.com/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.this.name}/providers/Microsoft.CognitiveServices/accounts/${jsondecode(azurerm_resource_group_template_deployment.ai_foundry.output_content).foundryAccountName.value}" />
#   </inbound>
#   <backend>
#     <base />
#   </backend>
#   <outbound>
#     <base />
#   </outbound>
#   <on-error>
#     <base />
#   </on-error>
# </policies>
# XML
# }
