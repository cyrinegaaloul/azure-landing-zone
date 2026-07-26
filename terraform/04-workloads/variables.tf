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

variable "aks_subnet_name" {
  description = "Logical subnet reserved for AKS"
  type        = string
  default     = "aks"
}
