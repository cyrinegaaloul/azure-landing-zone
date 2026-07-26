module "foundation" {
  source = "../00-foundation"

  subscription_id      = var.subscription_id
  location             = var.location
  project_name         = var.project_name
  environment          = var.environment
  owner                = var.owner
  cost_center          = var.cost_center
  resource_group_names = var.resource_group_names
  workload_name        = var.workload_name
  criticality          = var.criticality
  additional_tags      = var.additional_tags
}

module "networking" {
  source = "../01-networking"

  subscription_id     = var.subscription_id
  location            = module.foundation.location
  resource_group_name = module.foundation.resource_groups.network.name
  project_name        = var.project_name
  environment         = var.environment
  common_tags         = module.foundation.common_tags
  vnet_name_override  = var.vnet_name_override
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
}

module "security_baseline" {
  source = "../02-security-baseline"

  subscription_id      = var.subscription_id
  resource_groups      = module.foundation.resource_groups
  role_assignments     = var.role_assignments
  resource_group_locks = var.resource_group_locks
}

module "edge" {
  source = "../03-edge"

  subscription_id     = var.subscription_id
  location            = module.foundation.location
  project_name        = var.project_name
  environment         = var.environment
  resource_group_name = module.foundation.resource_groups.security.name
  common_tags         = module.foundation.common_tags
  enable_edge_stack   = var.enable_edge_stack
  edge_mode           = var.edge_mode
  waf_policy_mode     = var.waf_policy_mode
  apim_tier           = var.apim_tier
}

module "workloads" {
  source = "../04-workloads"

  subscription_id      = var.subscription_id
  location             = module.foundation.location
  project_name         = var.project_name
  environment          = var.environment
  resource_group_name  = module.foundation.resource_groups.foundation.name
  common_tags          = module.foundation.common_tags
  enable_aks_demo      = var.enable_aks_demo
  enable_jelastic_demo = var.enable_jelastic_demo
  application_name     = var.application_name
  container_image_name = var.container_image_name
  container_port       = var.container_port
  kubernetes_namespace = var.kubernetes_namespace
}

module "observability" {
  source = "../05-observability"

  subscription_id           = var.subscription_id
  location                  = module.foundation.location
  project_name              = var.project_name
  environment               = var.environment
  resource_group_name       = module.foundation.resource_groups.security.name
  enable_observability_demo = var.enable_observability_demo
  prometheus_mode           = var.prometheus_mode
  grafana_mode              = var.grafana_mode
}

module "devsecops" {
  source = "../06-devsecops"

  subscription_id         = var.subscription_id
  project_name            = var.project_name
  environment             = var.environment
  enable_demo_deployments = var.enable_demo_deployments
  repository_name         = var.repository_name
  default_branch          = var.default_branch
  terraform_root_path     = var.terraform_root_path
  application_path        = var.application_path
}
