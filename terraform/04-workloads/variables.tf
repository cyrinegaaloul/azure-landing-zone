variable "subscription_id" {
  description = "Azure subscription ID used for the deployment"
  type        = string
}

variable "location" {
  description = "Azure region used for workload resources"
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
  description = "Existing resource group reserved for workload resources"
  type        = string
}

variable "common_tags" {
  description = "Tags inherited from the foundation module"
  type        = map(string)
  default     = {}
}

variable "enable_aks_demo" {
  description = "Controls whether AKS planning is enabled"
  type        = bool
  default     = false
}

variable "enable_jelastic_demo" {
  description = "Controls whether Jelastic P4D planning is enabled"
  type        = bool
  default     = false
}

variable "application_name" {
  description = "Application name shared by future workloads"
  type        = string
  default     = "landing-zone-demo-app"
}

variable "container_image_name" {
  description = "Container image reference used by AKS and Jelastic planning"
  type        = string
  default     = "landing-zone-demo-app:latest"
}

variable "container_registry_mode" {
  description = "Container registry approach for the application image"
  type        = string
  default     = "external"

  validation {
    condition     = contains(["external", "acr", "local-only"], var.container_registry_mode)
    error_message = "container_registry_mode must be external, acr, or local-only."
  }
}

variable "container_registry_server" {
  description = "Container registry server used to store the application image"
  type        = string
  default     = ""
}

variable "image_pull_secret_name" {
  description = "Kubernetes image pull secret name used when a private registry is selected"
  type        = string
  default     = "registry-pull-secret"
}

variable "container_port" {
  description = "Container port exposed by the application"
  type        = number
  default     = 8080
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "demo"
}

variable "aks_subnet_name" {
  description = "Logical subnet reserved for AKS"
  type        = string
  default     = "aks"
}

variable "aks_cluster_name_override" {
  description = "Optional AKS cluster name override. Leave null to use the standard naming pattern."
  type        = string
  default     = null
}

variable "aks_node_vm_size" {
  description = "Planned AKS node VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "aks_node_count" {
  description = "Planned AKS node count"
  type        = number
  default     = 1
}

variable "kubernetes_service_type" {
  description = "Planned Kubernetes service type for the application"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.kubernetes_service_type)
    error_message = "kubernetes_service_type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "ingress_strategy" {
  description = "Planned ingress strategy for exposing the AKS application"
  type        = string
  default     = "deferred-to-edge"

  validation {
    condition     = contains(["deferred-to-edge", "internal-only", "ingress-controller"], var.ingress_strategy)
    error_message = "ingress_strategy must be deferred-to-edge, internal-only, or ingress-controller."
  }
}

variable "application_replica_count" {
  description = "Planned replica count for the application in AKS"
  type        = number
  default     = 1
}

variable "configuration_mode" {
  description = "Configuration delivery approach for the application"
  type        = string
  default     = "configmap"

  validation {
    condition     = contains(["configmap", "envvars", "hybrid"], var.configuration_mode)
    error_message = "configuration_mode must be configmap, envvars, or hybrid."
  }
}

variable "secret_mode" {
  description = "Secret delivery approach for the application"
  type        = string
  default     = "kubernetes-secret"

  validation {
    condition     = contains(["kubernetes-secret", "external-secret", "key-vault-csi"], var.secret_mode)
    error_message = "secret_mode must be kubernetes-secret, external-secret, or key-vault-csi."
  }
}

variable "secret_names" {
  description = "Logical secret names used by the application deployment"
  type        = list(string)
  default     = ["app-secrets"]
}
