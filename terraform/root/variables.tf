variable "subscription_id" {
  description = "Azure subscription ID used by the root provider"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
  }
}

variable "location" {
  description = "Primary Azure region used by the landing zone"
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
  description = "Short project identifier used in Azure resource names"
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

variable "vnet_address_space" {
  description = "Address space allocated to the landing zone virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnets" {
  description = "Subnet definitions reserved for landing zone layers"
  type = map(object({
    address_prefixes = list(string)
    create_nsg       = optional(bool, true)
  }))

  default = {
    management = {
      address_prefixes = ["10.10.0.0/24"]
      create_nsg       = true
    }
    private-endpoints = {
      address_prefixes = ["10.10.1.0/24"]
      create_nsg       = true
    }
    aks = {
      address_prefixes = ["10.10.2.0/24"]
      create_nsg       = true
    }
    appgw = {
      address_prefixes = ["10.10.3.0/24"]
      create_nsg       = true
    }
    apim = {
      address_prefixes = ["10.10.4.0/24"]
      create_nsg       = true
    }
  }
}

variable "role_assignments" {
  description = "RBAC assignments keyed by a logical assignment name"
  type = map(object({
    scope_key            = string
    role_definition_name = string
    principal_id         = string
    principal_type       = optional(string)
    description          = optional(string)
  }))
  default = {}
}

variable "resource_group_locks" {
  description = "Optional management locks keyed by resource group logical name"
  type = map(object({
    level = string
    notes = optional(string, "Managed by Terraform")
  }))
  default = {}
}

variable "enable_aks_demo" {
  description = "Controls whether the AKS cluster resource is enabled"
  type        = bool
  default     = false
}

variable "aks_node_count" {
  description = "AKS node count"
  type        = number
  default     = 1
}

variable "aks_node_vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_B2s"
}
