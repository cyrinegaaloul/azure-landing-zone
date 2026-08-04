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

variable "nsg_rules" {
  description = "NSG rules keyed by logical rule name; subnet keys resolve to CIDRs from var.subnets"
  type = map(object({
    nsg_key                    = string
    priority                   = number
    direction                  = string
    access                     = optional(string, "Allow")
    protocol                   = optional(string, "Tcp")
    source_port_range          = optional(string, "*")
    destination_port_ranges    = list(string)
    source_address_prefix      = optional(string)
    source_subnet_key          = optional(string)
    destination_address_prefix = optional(string)
    destination_subnet_key     = optional(string)
    description                = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for rule in values(var.nsg_rules) :
      contains(["Inbound", "Outbound"], rule.direction) &&
      contains(["Allow", "Deny"], rule.access) &&
      contains(["Tcp", "Udp", "Icmp", "*"], rule.protocol) &&
      rule.priority >= 100 && rule.priority <= 4096 &&
      length(rule.destination_port_ranges) > 0
    ])
    error_message = "Each NSG rule must use a supported direction, access, and protocol, priority 100-4096, and at least one destination port."
  }

  validation {
    condition = alltrue([
      for rule in values(var.nsg_rules) :
      (rule.source_address_prefix == null) != (rule.source_subnet_key == null) &&
      (rule.destination_address_prefix == null) != (rule.destination_subnet_key == null)
    ])
    error_message = "Each NSG rule must set exactly one source selector and one destination selector, using either an address prefix or a subnet key."
  }

  validation {
    condition = length(distinct([
      for rule in values(var.nsg_rules) :
      "${rule.nsg_key}:${rule.direction}:${rule.priority}"
    ])) == length(var.nsg_rules)
    error_message = "NSG rule priorities must be unique within each target NSG and direction."
  }
}
