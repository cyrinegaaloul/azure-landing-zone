output "foundation" {
  description = "Foundation module outputs"
  value = {
    resource_groups = module.foundation.resource_groups
    location        = module.foundation.location
    common_tags     = module.foundation.common_tags
  }
}

output "networking" {
  description = "Networking module outputs"
  value = {
    virtual_network = module.networking.virtual_network
    subnets         = module.networking.subnets
  }
}

output "security_baseline" {
  description = "Key Vault details when enabled, otherwise null"
  value       = module.security_baseline.key_vault
}

output "edge" {
  description = "Application Gateway edge resources when enabled, otherwise null"
  value       = module.edge.edge
}

output "apim" {
  description = "API Management resources when enabled, otherwise null"
  value       = module.apim.apim
}

output "workloads" {
  description = "AKS workload module outputs"
  sensitive   = true
  value = {
    aks_cluster             = module.workloads.aks_cluster
    workload_identity       = module.workloads.workload_identity
    application_backend_url = module.workloads.application_backend_url
  }
}
