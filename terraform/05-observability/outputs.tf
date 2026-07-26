output "observability_plan" {
  description = "Planned observability configuration for the final demo"
  value = {
    resource_group_name = var.resource_group_name
    location            = var.location
    name_prefix         = local.name_prefix
    stack               = local.planned_observability
  }
}
