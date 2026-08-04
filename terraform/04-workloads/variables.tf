variable "location" {
  type = string
}

variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "enable_aks_demo" {
  type    = bool
  default = false
}

variable "enable_key_vault" {
  type    = bool
  default = false
}

variable "enable_edge_stack" {
  description = "Enables the managed AGIC add-on when AKS is also enabled"
  type        = bool
  default     = false
}

variable "application_gateway_id" {
  description = "ID of the existing WAF_v2 Application Gateway used by AGIC"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_edge_stack || var.application_gateway_id != null
    error_message = "application_gateway_id is required when enable_edge_stack is true."
  }
}

variable "key_vault_id" {
  description = "Key Vault resource ID used for the application identity role assignment"
  type        = string
  default     = null
}

variable "aks_subnet_id" {
  type = string
}

variable "aks_node_count" {
  type    = number
  default = 1
}

variable "aks_node_vm_size" {
  type    = string
  default = "Standard_B2s"
}
