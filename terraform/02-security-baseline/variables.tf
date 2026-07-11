variable "subscription_id" {
  description = "Azure subscription ID used for the deployment"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
  }
}

variable "resource_groups" {
  description = "Resource groups created by the foundation module keyed by logical name"
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

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) : contains(keys(var.resource_groups), assignment.scope_key)
    ])
    error_message = "Each role assignment scope_key must match one of the defined resource_groups."
  }
}

variable "resource_group_locks" {
  description = "Optional management locks keyed by resource group logical name"
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
