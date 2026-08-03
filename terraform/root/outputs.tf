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
  }
}

output "security_baseline" {
  description = "Security baseline module outputs"
  value = {
    role_assignments     = module.security_baseline.role_assignments
    resource_group_locks = module.security_baseline.resource_group_locks
  }
}

output "workloads" {
  description = "AKS workload module outputs"
  value = {
    aks_cluster = module.workloads.aks_cluster
  }
}
