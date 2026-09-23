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
