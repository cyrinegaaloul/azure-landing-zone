variable "subscription_id" {
  description = "Azure subscription ID used for the deployment"
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

variable "container_image_name" {
  description = "Container image name used by the delivery workflow"
  type        = string
  default     = "landing-zone-demo-app"
}

variable "container_registry_mode" {
  description = "Container registry approach used by the delivery workflow"
  type        = string
  default     = "external"

  validation {
    condition     = contains(["external", "acr", "local-only"], var.container_registry_mode)
    error_message = "container_registry_mode must be external, acr, or local-only."
  }
}

variable "container_registry_server" {
  description = "Container registry server used by the delivery workflow"
  type        = string
  default     = ""
}

variable "image_tag_strategy" {
  description = "Image tag strategy used by CI/CD"
  type        = string
  default     = "git-sha"

  validation {
    condition     = contains(["git-sha", "git-sha-and-latest", "semver"], var.image_tag_strategy)
    error_message = "image_tag_strategy must be git-sha, git-sha-and-latest, or semver."
  }
}

variable "kubernetes_manifest_path" {
  description = "Kubernetes manifest path used by the delivery workflow"
  type        = string
  default     = "app/k8s"
}

variable "secret_strategy" {
  description = "Secret handling approach expected by the delivery workflow"
  type        = string
  default     = "kubernetes-secret"

  validation {
    condition     = contains(["kubernetes-secret", "external-secret", "key-vault-csi"], var.secret_strategy)
    error_message = "secret_strategy must be kubernetes-secret, external-secret, or key-vault-csi."
  }
}
