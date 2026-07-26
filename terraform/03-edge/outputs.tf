output "edge_plan" {
  description = "Planned edge stack configuration reserved for the final demo"
  value = {
    resource_group_name = var.resource_group_name
    location            = var.location
    name_prefix         = local.name_prefix
    resources           = local.planned_resources
  }
}
