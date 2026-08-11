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

variable "grant_current_user_backend_access" {
  description = "Grant the identity running the bootstrap Storage Blob Data Contributor access to the Terraform state backend."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to backend resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
    purpose    = "terraform-state"
  }
}
