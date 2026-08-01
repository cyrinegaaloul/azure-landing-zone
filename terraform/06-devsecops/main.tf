locals {
  name_prefix = "${var.project_name}-${var.environment}"

  pipeline_plan = {
    validation = {
      terraform_fmt      = true
      terraform_init     = true
      terraform_validate = true
      terraform_plan     = true
      python_checks      = true
      docker_build       = true
      kubernetes_lint    = true
    }
    security = {
      iac_scan        = true
      dependency_scan = true
      container_scan  = true
    }
    image_delivery = {
      image_name      = var.container_image_name
      registry_mode   = var.container_registry_mode
      registry_server = var.container_registry_server
      tag_strategy    = var.image_tag_strategy
      manifest_path   = var.kubernetes_manifest_path
      secret_strategy = var.secret_strategy
      publish_mode    = var.enable_demo_deployments ? "manual-release-window" : "build-only"
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
