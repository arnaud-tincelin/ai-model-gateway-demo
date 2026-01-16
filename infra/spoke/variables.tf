variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The location/region where resources will be deployed"
  type        = string
}

variable "model_gateway" {
  description = "Information about Model Gateway"
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
