variable "subscription_id" {
  description = "Azure subscription ID used by the root provider"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by tenant-scoped Azure resources"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID."
  }
}

variable "location" {
  description = "Primary Azure region used by the landing zone"
  type        = string
  default     = "francecentral"

  validation {
    condition = contains(
      [
        "francecentral",
        "westeurope",
        "northeurope"
      ],
      var.location
    )

    error_message = "location must be francecentral, westeurope, or northeurope."
  }
}

variable "project_name" {
  description = "Short project identifier used in Azure resource names"
  type        = string
  default     = "alz"

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9-]{0,13}[a-z0-9]$", var.project_name)) &&
      !strcontains(var.project_name, "--")
    )
    error_message = "project_name must contain 2 to 15 lowercase letters, numbers, or single hyphens, and must start and end with a letter or number."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "owner" {
  description = "Person or team responsible for the deployed resources"
  type        = string
  default     = "cyrine"

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "vnet_address_space" {
  description = "Address space allocated to the landing zone virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnets" {
  description = "Subnet definitions reserved for landing zone layers"
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
}

variable "nsg_rules" {
  description = "Approved environment NSG rules keyed by logical rule name"
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

  default = {
    internet-to-appgw-https = {
      nsg_key                 = "appgw"
      priority                = 100
      direction               = "Inbound"
      destination_port_ranges = ["443"]
      source_address_prefix   = "Internet"
      destination_subnet_key  = "appgw"
      description             = "Future public HTTPS entry through Application Gateway only"
    }
    azure-load-balancer-to-aks-probes = {
      nsg_key                 = "aks"
      priority                = 100
      direction               = "Inbound"
      destination_port_ranges = ["30000-32767"]
      source_address_prefix   = "AzureLoadBalancer"
      destination_subnet_key  = "aks"
      description             = "Future AKS load-balancer health probes over the default NodePort range"
    }
    appgw-to-aks-web = {
      nsg_key                 = "aks"
      priority                = 200
      direction               = "Inbound"
      destination_port_ranges = ["80", "443"]
      source_subnet_key       = "appgw"
      destination_subnet_key  = "aks"
      description             = "Future Application Gateway forwarding to AKS web endpoints"
    }
    aks-to-private-endpoints-https = {
      nsg_key                 = "private-endpoints"
      priority                = 200
      direction               = "Inbound"
      destination_port_ranges = ["443"]
      source_subnet_key       = "aks"
      destination_subnet_key  = "private-endpoints"
      description             = "AKS access to Key Vault and future private endpoints over HTTPS"
    }
    aks-to-internet-https = {
      nsg_key                    = "aks"
      priority                   = 200
      direction                  = "Outbound"
      destination_port_ranges    = ["443"]
      source_subnet_key          = "aks"
      destination_address_prefix = "Internet"
      description                = "AKS image pulls and required external HTTPS endpoints"
    }
  }

  validation {
    condition = alltrue([
      for rule in values(var.nsg_rules) :
      rule.protocol == "Tcp" &&
      rule.access == "Allow" &&
      !contains(rule.destination_port_ranges, "*") &&
      rule.source_address_prefix != "*" &&
      rule.source_address_prefix != "0.0.0.0/0"
    ])
    error_message = "Root NSG rules must be explicit TCP allow rules without wildcard ports or unrestricted source prefixes."
  }
}

variable "enable_management_access" {
  description = "Creates an internal management-subnet SSH/RDP rule to the AKS subnet when explicitly enabled"
  type        = bool
  default     = false
}

variable "enable_edge_stack" {
  description = "Controls the billable Application Gateway WAF_v2 edge stack and AGIC integration"
  type        = bool
  default     = false
}

variable "waf_policy_mode" {
  description = "WAF policy mode for the Application Gateway"
  type        = string
  default     = "Detection"

  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_policy_mode)
    error_message = "waf_policy_mode must be Detection or Prevention."
  }
}

variable "enable_apim" {
  description = "Controls the billable Developer-tier API Management demo stage"
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_apim || var.enable_edge_stack
    error_message = "enable_apim requires enable_edge_stack so APIM has a real Application Gateway backend."
  }
}

variable "apim_sku_name" {
  description = "API Management SKU for the demo stage"
  type        = string
  default     = "Developer_1"

  validation {
    condition     = var.apim_sku_name == "Developer_1"
    error_message = "apim_sku_name must be Developer_1 for this non-production demo stage."
  }
}

variable "role_assignments" {
  description = "RBAC assignments keyed by a logical assignment name"
  type = map(object({
    scope_key            = string
    role_definition_name = string
    principal_id         = string
    principal_type       = optional(string)
    description          = optional(string)
  }))
  default = {}
}

variable "resource_group_locks" {
  description = "Optional management locks keyed by resource group logical name"
  type = map(object({
    level = string
    notes = optional(string, "Managed by Terraform")
  }))
  default = {}
}

variable "enable_key_vault" {
  description = "Controls whether the landing zone Key Vault is enabled"
  type        = bool
  default     = false
}

variable "enable_aks_demo" {
  description = "Controls whether the AKS cluster resource is enabled"
  type        = bool
  default     = false
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
