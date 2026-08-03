module "foundation" {
  source = "../00-foundation"

  location     = var.location
  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner
}

module "networking" {
  source = "../01-networking"

  location            = module.foundation.location
  resource_group_name = module.foundation.resource_groups.network.name
  project_name        = var.project_name
  environment         = var.environment
  common_tags         = module.foundation.common_tags
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
}

module "security_baseline" {
  source = "../02-security-baseline"

  resource_groups      = module.foundation.resource_groups
  role_assignments     = var.role_assignments
  resource_group_locks = var.resource_group_locks
}

module "workloads" {
  source = "../04-workloads"

  location            = module.foundation.location
  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.foundation.resource_groups.foundation.name
  common_tags         = module.foundation.common_tags
  enable_aks_demo     = var.enable_aks_demo
  aks_subnet_id       = module.networking.subnets["aks"].id
  aks_node_count      = var.aks_node_count
  aks_node_vm_size    = var.aks_node_vm_size
}
