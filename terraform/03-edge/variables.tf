variable "location" {
  description = "Azure region for edge resources"
  type        = string
}

variable "project_name" {
  description = "Short project identifier used in edge resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "resource_group_name" {
  description = "Network resource group containing Application Gateway"
  type        = string
}

variable "common_tags" {
  description = "Tags shared with the landing zone"
  type        = map(string)
  default     = {}
}

variable "enable_edge_stack" {
  description = "Controls creation of the public IP, WAF policy, and Application Gateway"
  type        = bool
  default     = false
}

variable "app_gateway_subnet_id" {
  description = "Dedicated Application Gateway subnet ID"
  type        = string
}

variable "waf_policy_mode" {
  description = "Application Gateway WAF policy operating mode"
  type        = string
  default     = "Detection"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_policy_mode)
    error_message = "waf_policy_mode must be Detection or Prevention."
  }
}

variable "health_probe_path" {
  description = "Bootstrap backend health probe path"
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.health_probe_path, "/")
    error_message = "health_probe_path must start with /."
  }
}

variable "application_gateway_capacity" {
  description = "Fixed WAF_v2 capacity for the temporary demonstration"
  type        = number
  default     = 1

  validation {
    condition     = var.application_gateway_capacity >= 1 && var.application_gateway_capacity <= 125
    error_message = "application_gateway_capacity must be between 1 and 125."
  }
}

