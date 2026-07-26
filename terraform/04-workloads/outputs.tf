output "workload_plan" {
  description = "Planned workload configuration for AKS, Jelastic P4D, and the shared demo application"
  value = {
    resource_group_name = var.resource_group_name
    location            = var.location
    name_prefix         = local.name_prefix
    workloads           = local.planned_workloads
  }
}
