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

variable "owner" {
  description = "Owner identifier used as the globally unique APIM name suffix."
  type        = string

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.owner)) &&
      !strcontains(var.owner, "--") &&
      length("apim-${var.project_name}-${var.environment}-${var.owner}") <= 50
    )
    error_message = "owner must produce a valid APIM name of at most 50 alphanumeric or hyphen characters that starts and ends with an alphanumeric character."
  }
}

variable "publisher_name" {
  description = "Publisher name displayed by API Management."
  type        = string
  default     = "Cyrine Gaaloul"

  validation {
    condition     = length(trimspace(var.publisher_name)) > 0
    error_message = "publisher_name must not be empty."
  }
}

variable "publisher_email" {
  description = "Publisher contact email displayed by API Management."
  type        = string
  default     = "cyrinegaaloull@gmail.com"

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.publisher_email))
    error_message = "publisher_email must be a valid email address."
  }
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
  description = "Internal AKS LoadBalancer URL used as the imported API backend."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = !var.enable_apim || try(startswith(var.backend_url, "http://") || startswith(var.backend_url, "https://"), false)
    error_message = "backend_url must be a non-null HTTP(S) URL when API Management is enabled."
  }
}

variable "apim_subnet_id" {
  description = "Repository-reserved, non-delegated subnet ID used for classic API Management internal VNet injection."
  type        = string
}

variable "virtual_network_id" {
  description = "Virtual network ID linked to exact-hostname private DNS zones for internal API Management endpoints."
  type        = string
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
