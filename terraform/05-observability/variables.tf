variable "subscription_id" {
  description = "Azure subscription ID used for the deployment"
  type        = string
}

variable "location" {
  description = "Azure region used for observability resources"
  type        = string
}

variable "project_name" {
  description = "Short project identifier used in Azure resource names and tags"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group reserved for observability resources"
  type        = string
}

variable "enable_observability_demo" {
  description = "Controls whether the observability stack is intended for deployment in the final demo"
  type        = bool
  default     = false
}

variable "prometheus_mode" {
  description = "Planned Prometheus approach for the final demo"
  type        = string
  default     = "self-managed"

  validation {
    condition     = contains(["self-managed", "azure-monitor-managed"], var.prometheus_mode)
    error_message = "prometheus_mode must be self-managed or azure-monitor-managed."
  }
}

variable "grafana_mode" {
  description = "Planned Grafana approach for the final demo"
  type        = string
  default     = "dashboard-only"

  validation {
    condition     = contains(["dashboard-only", "azure-managed", "self-managed"], var.grafana_mode)
    error_message = "grafana_mode must be dashboard-only, azure-managed, or self-managed."
  }
}
