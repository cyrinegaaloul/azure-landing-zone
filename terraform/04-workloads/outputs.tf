output "workload_plan" {
  description = "Planned workload configuration with an AKS-first deployment path and future Jelastic option"
  value = {
    resource_group_name = var.resource_group_name
    location            = var.location
    name_prefix         = local.name_prefix
    workloads           = local.planned_workloads
  }
}

output "aks_cluster_plan" {
  description = "Planned AKS cluster configuration"
  value       = local.aks_cluster_plan
}

output "application_plan" {
  description = "Planned application deployment configuration for AKS"
  value       = local.application_plan
}

output "kubernetes_artifacts" {
  description = "Kubernetes manifest files prepared for the application"
  value       = local.kubernetes_artifacts
}
