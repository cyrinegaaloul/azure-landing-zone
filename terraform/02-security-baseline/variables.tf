variable "resource_groups" {
  type = map(object({
    name = string
    id   = string
  }))

  validation {
    condition = alltrue([
      for required_key in ["foundation", "network", "security"] : contains(keys(var.resource_groups), required_key)
    ])
    error_message = "resource_groups must include foundation, network, and security entries."
  }
}

variable "location" {
  description = "Azure region used by security baseline resources"
  type        = string
}

variable "project_name" {
  description = "Short project identifier used in Azure resource names"
  type        = string

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9-]{0,13}[a-z0-9]$", var.project_name)) &&
      !strcontains(var.project_name, "--")
    )
    error_message = "project_name must contain 2 to 15 lowercase letters, numbers, or single hyphens, and must start and end with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "owner" {
  description = "Owner identifier used as the globally unique Key Vault name suffix"
  type        = string

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.owner)) &&
      !strcontains(var.owner, "--") &&
      length("kv-${var.project_name}-${var.environment}-${var.owner}") <= 24
    )
    error_message = "owner must produce a valid Key Vault name of 3 to 24 lowercase alphanumeric or hyphen characters without consecutive hyphens."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by Azure Key Vault"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID."
  }
}

variable "common_tags" {
  description = "Tags inherited from the foundation module"
  type        = map(string)
  default     = {}
}

variable "enable_key_vault" {
  description = "Controls whether the landing zone Key Vault is enabled"
  type        = bool
  default     = false
}

variable "enable_key_vault_purge_protection" {
  description = "Enables irreversible purge protection on the Key Vault"
  type        = bool
  default     = false
}

variable "key_vault_public_network_access_enabled" {
  description = "Controls public network connectivity to the Key Vault"
  type        = bool
  default     = true
}

variable "role_assignments" {
  type = map(object({
    scope_key            = string
    role_definition_name = string
    principal_id         = string
    principal_type       = optional(string, "Group")
    description          = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      contains(keys(var.resource_groups), assignment.scope_key) &&
      !contains(["Owner", "User Access Administrator"], assignment.role_definition_name) &&
      contains(["Group", "ServicePrincipal"], assignment.principal_type) &&
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", assignment.principal_id))
    ])
    error_message = "Each role assignment must target a defined resource group, avoid Owner and User Access Administrator, use Group or ServicePrincipal, and provide a valid object ID."
  }
}

variable "resource_group_locks" {
  type = map(object({
    level = string
    notes = optional(string, "Managed by Terraform")
  }))
  default = {}

  validation {
    condition = alltrue([
      for rg_key, lock in var.resource_group_locks :
      contains(keys(var.resource_groups), rg_key) && contains(["CanNotDelete", "ReadOnly"], lock.level)
    ])
    error_message = "resource_group_locks keys must exist in resource_groups and levels must be CanNotDelete or ReadOnly."
  }
}
