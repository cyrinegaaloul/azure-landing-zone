variable "subscription_id" {
  description = "Azure subscription ID used by the root provider"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID used by tenant-scoped Azure resources"
  type        = string
  sensitive   = true

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
  description = "Lowercase owner identifier used in tags and globally unique resource names"
  type        = string
  default     = "cyrine"

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.owner)) &&
      !strcontains(var.owner, "--") &&
      length("kv-${var.project_name}-${var.environment}-${var.owner}") <= 24
    )
    error_message = "owner must contain at least two lowercase letters, numbers, or single hyphens, must start and end with a letter or number, and must keep the generated Key Vault name within 24 characters."
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
  description = "Controls the billable Application Gateway WAF_v2 public frontend"
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
    condition     = !var.enable_apim || (var.enable_edge_stack && var.enable_aks_demo)
    error_message = "enable_apim requires enable_edge_stack and enable_aks_demo for the Application Gateway -> internal APIM -> AKS path."
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
    principal_type       = optional(string, "Group")
    description          = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for assignment in values(var.role_assignments) :
      !contains(["Owner", "User Access Administrator"], assignment.role_definition_name) &&
      contains(["Group", "ServicePrincipal"], assignment.principal_type) &&
      can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", assignment.principal_id))
    ])
    error_message = "role_assignments cannot grant Owner or User Access Administrator, must target a Group or ServicePrincipal, and must use a valid object ID."
  }
}

variable "platform_admin_group_object_id" {
  description = "Optional Microsoft Entra group object ID granted Contributor on the foundation resource group"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.platform_admin_group_object_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.platform_admin_group_object_id))
    error_message = "platform_admin_group_object_id must be null or a valid Microsoft Entra object ID."
  }
}

variable "network_operator_group_object_id" {
  description = "Optional Microsoft Entra group object ID granted Network Contributor on the network resource group"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.network_operator_group_object_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.network_operator_group_object_id))
    error_message = "network_operator_group_object_id must be null or a valid Microsoft Entra object ID."
  }
}

variable "security_reader_group_object_id" {
  description = "Optional Microsoft Entra group object ID granted Security Reader on the security resource group"
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.security_reader_group_object_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.security_reader_group_object_id))
    error_message = "security_reader_group_object_id must be null or a valid Microsoft Entra object ID."
  }
}

variable "resource_group_locks" {
  description = "Optional management locks keyed by resource group logical name"
  type = map(object({
    level = string
    notes = optional(string, "Managed by Terraform")
  }))
  default = {}
}

variable "enable_resource_group_locks" {
  description = "Enables CanNotDelete locks on the network and security resource groups"
  type        = bool
  default     = false
}

variable "enable_key_vault" {
  description = "Controls whether the landing zone Key Vault is enabled"
  type        = bool
  default     = false
}

variable "enable_key_vault_purge_protection" {
  description = "Enables irreversible Key Vault purge protection for protected environments"
  type        = bool
  default     = false
}

variable "key_vault_public_network_access_enabled" {
  description = "Allows public network connectivity to Key Vault; disable only after private networking is implemented"
  type        = bool
  default     = true
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
  default     = "Standard_B2s_v2"
}

variable "aks_internal_load_balancer_ip" {
  description = "Static private IP reserved in the AKS subnet for the application's internal Kubernetes LoadBalancer"
  type        = string
  default     = "10.10.2.10"

  validation {
    condition     = try(can(cidrhost("${var.aks_internal_load_balancer_ip}/32", 0)) && cidrcontains(var.subnets["aks"].address_prefixes[0], var.aks_internal_load_balancer_ip), false)
    error_message = "aks_internal_load_balancer_ip must be a valid IPv4 address inside the configured AKS subnet. Confirm that Azure has not already allocated it before deployment."
  }
}
