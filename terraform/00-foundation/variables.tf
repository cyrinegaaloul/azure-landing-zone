variable "location" {
  description = "Azure region for deployed resources"
  type        = string
  default     = "francecentral"

  validation {
    condition     = contains(["francecentral", "westeurope", "northeurope"], var.location)
    error_message = "location must be francecentral, westeurope, or northeurope."
  }
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "alz"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,15}$", var.project_name))
    error_message = "project_name must contain only lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "cyrine"

  validation {
    condition     = trimspace(var.owner) != ""
    error_message = "owner cannot be empty."
  }
}
