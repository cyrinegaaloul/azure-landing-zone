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

variable "enabled" {
  type    = bool
  default = false
}

variable "platform_admin_group_object_id" {
  description = "Optional Microsoft Entra platform-administrators group object ID granted Grafana Admin on the managed Grafana instance."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.platform_admin_group_object_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.platform_admin_group_object_id))
    error_message = "platform_admin_group_object_id must be null or a valid Microsoft Entra object ID."
  }
}
