output "devsecops_plan" {
  description = "Planned DevSecOps workflow for validation, image delivery, security scanning, and controlled deployment"
  value = {
    repository  = var.repository_name
    branch      = var.default_branch
    name_prefix = local.name_prefix
    pipeline    = local.pipeline_plan
  }
}
