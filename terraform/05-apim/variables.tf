variable "enable_apim" {
  description = "Whether to create the demo Azure API Management service and API."
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region in which to create API Management."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group that will contain API Management."
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment used in resource naming."
  type        = string
}

variable "apim_sku_name" {
  description = "API Management SKU. This demo stage intentionally supports only Developer_1."
  type        = string
  default     = "Developer_1"

  validation {
    condition     = var.apim_sku_name == "Developer_1"
    error_message = "apim_sku_name must be Developer_1 for this non-production demo stage."
  }
}

variable "backend_url" {
  description = "Backend base URL for the imported API. Set by the root module from the Application Gateway frontend."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = (
      var.backend_url == null ||
      startswith(var.backend_url, "http://") ||
      startswith(var.backend_url, "https://")
    )
    error_message = "backend_url must be null or an HTTP(S) URL."
  }
}

variable "openapi_spec_path" {
  description = "Path to the OpenAPI document imported into API Management."
  type        = string
}

variable "tags" {
  description = "Tags applied to API Management resources."
  type        = map(string)
  default     = {}
}

