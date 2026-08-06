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
  default = "Standard_B2s_v2"
}

variable "application_backend_ip" {
  description = "Static private IP reserved for the application's internal Kubernetes LoadBalancer"
  type        = string
}
