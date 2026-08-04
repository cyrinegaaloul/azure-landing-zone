module "foundation" {
  source = "../00-foundation"

  location     = var.location
  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner
}

locals {
  management_nsg_rules = var.enable_management_access ? {
    management-to-aks-admin = {
      nsg_key                 = "aks"
      priority                = 300
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = ["22", "3389"]
      source_subnet_key       = "management"
      destination_subnet_key  = "aks"
      description             = "Optional management-subnet SSH and RDP path to AKS subnet"
    }
  } : {}

  edge_nsg_rules = var.enable_edge_stack ? {
    internet-to-appgw-http-bootstrap = {
      nsg_key                 = "appgw"
      priority                = 110
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = ["80"]
      source_address_prefix   = "Internet"
      destination_subnet_key  = "appgw"
      description             = "Temporary public HTTP listener for the controlled Application Gateway demo"
    }
    gateway-manager-to-appgw-infrastructure = {
      nsg_key                 = "appgw"
      priority                = 120
      direction               = "Inbound"
      access                  = "Allow"
      protocol                = "Tcp"
      source_port_range       = "*"
      destination_port_ranges = ["65200-65535"]
      source_address_prefix   = "GatewayManager"
      destination_subnet_key  = "appgw"
      description             = "Required Application Gateway v2 infrastructure communication"
    }
  } : {}
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
  nsg_rules = merge(
    var.nsg_rules,
    local.management_nsg_rules,
    local.edge_nsg_rules
  )
}

module "edge" {
  source = "../03-edge"

  location              = module.foundation.location
  project_name          = var.project_name
  environment           = var.environment
  resource_group_name   = module.foundation.resource_groups.network.name
  common_tags           = module.foundation.common_tags
  enable_edge_stack     = var.enable_edge_stack
  app_gateway_subnet_id = module.networking.subnets["appgw"].id
  waf_policy_mode       = var.waf_policy_mode
}

module "apim" {
  source = "../05-apim"

  location            = module.foundation.location
  resource_group_name = module.foundation.resource_groups.network.name
  project_name        = var.project_name
  environment         = var.environment
  tags                = module.foundation.common_tags
  enable_apim         = var.enable_apim
  apim_sku_name       = var.apim_sku_name
  backend_url         = module.edge.edge == null ? null : "http://${module.edge.edge.public_ip.address}"
  openapi_spec_path   = "${path.root}/../../app/openapi.yaml"
}

module "security_baseline" {
  source = "../02-security-baseline"

  location             = var.location
  project_name         = var.project_name
  environment          = var.environment
  tenant_id            = var.tenant_id
  common_tags          = module.foundation.common_tags
  enable_key_vault     = var.enable_key_vault
  resource_groups      = module.foundation.resource_groups
  role_assignments     = var.role_assignments
  resource_group_locks = var.resource_group_locks
}

module "workloads" {
  source = "../04-workloads"

  location               = module.foundation.location
  project_name           = var.project_name
  environment            = var.environment
  resource_group_name    = module.foundation.resource_groups.foundation.name
  common_tags            = module.foundation.common_tags
  enable_aks_demo        = var.enable_aks_demo
  enable_edge_stack      = var.enable_edge_stack
  application_gateway_id = module.edge.edge == null ? null : module.edge.edge.application_gateway.id
  enable_key_vault       = var.enable_key_vault
  key_vault_id           = var.enable_key_vault ? module.security_baseline.key_vault.id : null
  aks_subnet_id          = module.networking.subnets["aks"].id
  aks_node_count         = var.aks_node_count
  aks_node_vm_size       = var.aks_node_vm_size
}

resource "azurerm_role_assignment" "agic_gateway_network_contributor" {
  count = var.enable_aks_demo && var.enable_edge_stack ? 1 : 0

  scope                            = module.edge.edge.application_gateway.id
  role_definition_name             = "Network Contributor"
  principal_id                     = module.workloads.agic_identity.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "agic_gateway_resource_group_reader" {
  count = var.enable_aks_demo && var.enable_edge_stack ? 1 : 0

  scope                            = module.foundation.resource_groups.network.id
  role_definition_name             = "Reader"
  principal_id                     = module.workloads.agic_identity.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "agic_gateway_subnet_network_contributor" {
  count = var.enable_aks_demo && var.enable_edge_stack ? 1 : 0

  scope                            = module.networking.subnets["appgw"].id
  role_definition_name             = "Network Contributor"
  principal_id                     = module.workloads.agic_identity.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
