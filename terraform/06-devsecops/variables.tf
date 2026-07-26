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
