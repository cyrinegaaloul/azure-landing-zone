output "foundation" {
  description = "Foundation module outputs"
  value = {
    resource_groups = module.foundation.resource_groups
    location        = module.foundation.location
    name_prefix     = module.foundation.name_prefix
    common_tags     = module.foundation.common_tags
  }
}

output "networking" {
  description = "Networking module outputs"
  value = {
    virtual_network         = module.networking.virtual_network
    subnets                 = module.networking.subnets
    network_security_groups = module.networking.network_security_groups
    network_security_rules  = module.networking.network_security_rules
  }
}

output "security_baseline" {
  description = "Security baseline module outputs"
  value = {
    role_assignments     = module.security_baseline.role_assignments
    resource_group_locks = module.security_baseline.resource_group_locks
    key_vault            = module.security_baseline.key_vault
  }
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
  value = {
    aks_cluster                  = module.workloads.aks_cluster
    workload_identity            = module.workloads.workload_identity
    key_vault_role_assignment_id = module.workloads.key_vault_role_assignment_id
    agic_identity                = module.workloads.agic_identity
  }
}
