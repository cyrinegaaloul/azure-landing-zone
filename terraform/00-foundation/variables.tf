variable "subscription_id" {
  description = "Azure subscription ID used for the deployment"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Primary Azure region used by the development environment"
  type        = string
  default     = "francecentral"

  validation {
    condition = contains(
      [
        "francecentral",
        "westeurope",
        "northeurope"
      ],
      var.location
    )

    error_message = "location must be francecentral, westeurope, or northeurope."
  }
}

variable "project_name" {
  description = "Short project identifier used in Azure resource names and tags"
  type        = string
  default     = "alz"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,15}$", var.project_name))
    error_message = "project_name must contain 2 to 15 lowercase letters, numbers, or hyphens."
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
  description = "Person or team responsible for the deployed resources"
  type        = string
  default     = "cyrine"

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "cost_center" {
  description = "Cost tracking identifier"
  type        = string
  default     = "student-credit"

  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "cost_center must not be empty."
  }
}

variable "resource_group_names" {
  description = "Logical names of the resource groups created by the foundation module"
  type = object({
    foundation = string
    network    = string
    security   = string
  })

  default = {
    foundation = "foundation"
    network    = "network"
    security   = "security"
  }
}

variable "workload_name" {
  description = "Workload tag value shared across the landing zone foundation resources"
  type        = string
  default     = "landing-zone"

  validation {
    condition     = length(trimspace(var.workload_name)) > 0
    error_message = "workload_name must not be empty."
  }
}

variable "criticality" {
  description = "Criticality tag applied to the landing zone foundation resources"
  type        = string
  default     = "low"

  validation {
    condition     = contains(["low", "medium", "high"], var.criticality)
    error_message = "criticality must be low, medium, or high."
  }
}

variable "additional_tags" {
  description = "Additional tags merged with the default landing zone tags"
  type        = map(string)
  default     = {}
}
