variable "subscription_id" {
  description = "Azure subscription that hosts the Terraform state resources"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for the state resource group and storage account"
  type        = string
  default     = "francecentral"
}

variable "project_name" {
  description = "Short project identifier used in backend resource names"
  type        = string
  default     = "alz"
}

variable "environment" {
  description = "Environment represented by the backend"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Lowercase suffix used to make the storage account name globally unique"
  type        = string
  default     = "cyrine"
}

variable "backend_principals" {
  description = "Optional local and GitHub OIDC principal object IDs granted access to blob state"
  type = map(object({
    object_id      = string
    principal_type = optional(string, "ServicePrincipal")
  }))
  default = {}

  validation {
    condition = alltrue([
      for principal in values(var.backend_principals) :
      can(regex("^[0-9a-fA-F-]{36}$", principal.object_id)) &&
      contains(["ServicePrincipal", "User", "Group"], principal.principal_type)
    ])
    error_message = "Each backend principal must use a valid object ID and supported principal type."
  }
}

variable "tags" {
  description = "Tags applied to backend resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
    purpose    = "terraform-state"
  }
}
