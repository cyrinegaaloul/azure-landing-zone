output "devsecops_plan" {
  description = "Planned DevSecOps workflow for validation, security scanning, and controlled demo deployment"
  value = {
    repository  = var.repository_name
    branch      = var.default_branch
    name_prefix = local.name_prefix
    pipeline    = local.pipeline_plan
  }
}
