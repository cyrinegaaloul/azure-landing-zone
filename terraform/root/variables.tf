variable "subscription_id" {
  description = "Azure subscription ID used for the deployment"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a valid Azure subscription UUID."
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
  description = "Short project identifier used in Azure resource names and tags"
  type        = string
  default     = "alz"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,15}$", var.project_name))
    error_message = "project_name must contain 2 to 15 lowercase letters, numbers, or hyphens."
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

variable "cost_center" {
  description = "Cost tracking identifier"
  type        = string
  default     = "student-credit"

  validation {
    condition     = length(trimspace(var.cost_center)) > 0
    error_message = "cost_center must not be empty."
  }
}

variable "resource_group_names" {
  description = "Logical names of the resource groups created by the foundation module"
  type = object({
    foundation = string
    network    = string
    security   = string
  })

  default = {
    foundation = "foundation"
    network    = "network"
    security   = "security"
  }
}

variable "workload_name" {
  description = "Workload tag value shared across the landing zone resources"
  type        = string
  default     = "landing-zone"
}

variable "criticality" {
  description = "Criticality tag applied to the landing zone resources"
  type        = string
  default     = "low"

  validation {
    condition     = contains(["low", "medium", "high"], var.criticality)
    error_message = "criticality must be low, medium, or high."
  }
}

variable "additional_tags" {
  description = "Additional tags merged with the default landing zone tags"
  type        = map(string)
  default     = {}
}

variable "vnet_name_override" {
  description = "Optional custom virtual network name. Leave null to use the standard naming pattern."
  type        = string
  default     = null
}

variable "vnet_address_space" {
  description = "Address space allocated to the landing zone virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "subnets" {
  description = "Subnet definitions reserved for future landing zone layers"
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

variable "enable_edge_stack" {
  description = "Controls whether the future edge stack is intended for the final demo"
  type        = bool
  default     = false
}

variable "edge_mode" {
  description = "Edge deployment mode for the final demo"
  type        = string
  default     = "deferred"
}

variable "waf_policy_mode" {
  description = "Planned WAF policy mode for the future edge stack"
  type        = string
  default     = "Prevention"
}

variable "apim_tier" {
  description = "Planned API Management tier for the final demo"
  type        = string
  default     = "Consumption"
}

variable "enable_aks_demo" {
  description = "Controls whether AKS is intended to be enabled for the final demo"
  type        = bool
  default     = false
}

variable "enable_jelastic_demo" {
  description = "Controls whether Jelastic P4D is intended to be enabled for the final demo"
  type        = bool
  default     = false
}

variable "application_name" {
  description = "Demo application name shared by future workloads"
  type        = string
  default     = "landing-zone-demo-app"
}

variable "container_image_name" {
  description = "Future container image reference used by AKS and Jelastic"
  type        = string
  default     = "landing-zone-demo-app:latest"
}

variable "container_port" {
  description = "Container port exposed by the demo application"
  type        = number
  default     = 8080
}

variable "kubernetes_namespace" {
  description = "Future Kubernetes namespace for the demo application"
  type        = string
  default     = "demo"
}

variable "enable_observability_demo" {
  description = "Controls whether the observability stack is intended for the final demo"
  type        = bool
  default     = false
}

variable "prometheus_mode" {
  description = "Planned Prometheus approach for the final demo"
  type        = string
  default     = "self-managed"
}

variable "grafana_mode" {
  description = "Planned Grafana approach for the final demo"
  type        = string
  default     = "dashboard-only"
}

variable "enable_demo_deployments" {
  description = "Controls whether deployment stages are intended to be active for the final demo"
  type        = bool
  default     = false
}

variable "repository_name" {
  description = "Repository name used by CI/CD documentation and future automation"
  type        = string
  default     = "azure-landing-zone"
}

variable "default_branch" {
  description = "Default Git branch used by CI/CD"
  type        = string
  default     = "main"
}

variable "terraform_root_path" {
  description = "Terraform root module path used by CI/CD"
  type        = string
  default     = "terraform/root"
}

variable "application_path" {
  description = "Application path used by CI/CD"
  type        = string
  default     = "app"
}
