variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location/region where resources will be deployed"
  type        = string
}

variable "model_gateway_gold" {
  description = "Information about Model Gateway for Gold tier (no rate limiting)"
  type = object({
    url     = string
    api_key = string
    metadata = object({
      deploymentInPath     = bool
      inferenceAPIVersion  = string
      deploymentAPIVersion = optional(string)
      models = list(object({
        name = string
        properties = object({
          model = object({
            name    = string
            version = string
            format  = string
          })
        })
      }))
    })
  })
}

variable "model_gateway_bronze" {
  description = "Information about Model Gateway for Bronze tier (token rate limited)"
  type = object({
    url     = string
    api_key = string
    metadata = object({
      deploymentInPath     = bool
      inferenceAPIVersion  = string
      deploymentAPIVersion = optional(string)
      models = list(object({
        name = string
        properties = object({
          model = object({
            name    = string
            version = string
            format  = string
          })
        })
      }))
    })
  })
}
