variable "subscription_id" {
  description = "Azure subscription ID used for the deployment"
  type        = string
}

variable "location" {
  description = "Azure region used for edge resources"
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
  description = "Existing resource group reserved for shared edge or security services"
  type        = string
}

variable "common_tags" {
  description = "Tags inherited from the foundation module"
  type        = map(string)
  default     = {}
}

variable "enable_edge_stack" {
  description = "Controls whether the future edge stack is intended for deployment in a demo environment"
  type        = bool
  default     = false
}

variable "edge_mode" {
  description = "Edge deployment mode for the final demo"
  type        = string
  default     = "deferred"

  validation {
    condition     = contains(["deferred", "demo"], var.edge_mode)
    error_message = "edge_mode must be deferred or demo."
  }
}

variable "app_gateway_subnet_name" {
  description = "Logical subnet reserved for Application Gateway"
  type        = string
  default     = "appgw"
}

variable "apim_subnet_name" {
  description = "Logical subnet reserved for API Management"
  type        = string
  default     = "apim"
}

variable "waf_policy_mode" {
  description = "Planned WAF mode for the future edge stack"
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_policy_mode)
    error_message = "waf_policy_mode must be Detection or Prevention."
  }
}

variable "apim_tier" {
  description = "Planned API Management tier for the demo"
  type        = string
  default     = "Consumption"
}
