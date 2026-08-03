variable "location" {
  type    = string
  default = "francecentral"

  validation {
    condition = contains(
      ["francecentral", "westeurope", "northeurope"],
      var.location
    )

    error_message = "location must be francecentral, westeurope, or northeurope."
  }
}

variable "resource_group_name" {
  type = string

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name must not be empty."
  }
}

variable "project_name" {
  type    = string
  default = "alz"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,15}$", var.project_name))
    error_message = "project_name must contain 2 to 15 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "common_tags" {
  type = map(string)
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.10.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "vnet_address_space must contain at least one CIDR block."
  }
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
    create_nsg       = optional(bool, true)
  }))

  default = {
    management = {
      address_prefixes = ["10.10.0.0/24"]
      create_nsg       = true
    }

    private-endpoints = {
      address_prefixes = ["10.10.1.0/24"]
      create_nsg       = true
    }

    aks = {
      address_prefixes = ["10.10.2.0/24"]
      create_nsg       = true
    }

    appgw = {
      address_prefixes = ["10.10.3.0/24"]
      create_nsg       = true
    }

    apim = {
      address_prefixes = ["10.10.4.0/24"]
      create_nsg       = true
    }
  }

  validation {
    condition     = length(var.subnets) > 0
    error_message = "subnets must define at least one subnet."
  }
}
