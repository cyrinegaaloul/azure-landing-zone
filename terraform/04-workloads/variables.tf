variable "location" {
  description = "Azure region used for workload resources"
  type        = string
}

variable "project_name" {
  description = "Short project identifier used in Azure resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group reserved for workload resources"
  type        = string
}

variable "common_tags" {
  description = "Tags inherited from the foundation module"
  type        = map(string)
  default     = {}
}

variable "enable_aks_demo" {
  description = "Controls whether the AKS cluster resource is enabled"
  type        = bool
  default     = false
}

variable "aks_subnet_id" {
  description = "Subnet ID reserved for AKS nodes"
  type        = string
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
