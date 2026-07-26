locals {
  name_prefix = "${var.project_name}-${var.environment}"

  pipeline_plan = {
    validation = {
      terraform_fmt      = true
      terraform_init     = true
      terraform_validate = true
      terraform_plan     = true
      python_checks      = true
    }
    security = {
      iac_scan        = true
      dependency_scan = true
      container_scan  = true
    }
    deployment = {
      enabled          = var.enable_demo_deployments
      branch           = var.default_branch
      terraform_root   = var.terraform_root_path
      application_path = var.application_path
      strategy         = var.enable_demo_deployments ? "manual_demo_approval" : "validate_only"
    }
  }
}
