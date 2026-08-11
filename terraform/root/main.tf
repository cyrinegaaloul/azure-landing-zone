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

  edge_nsg_rules = {
    for name, rule in {
      internet-to-appgw-http-bootstrap = {
        nsg_key                    = "appgw"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80"]
        source_address_prefix      = "Internet"
        source_subnet_key          = null
        destination_subnet_key     = "appgw"
        destination_address_prefix = null
        description                = "Temporary public HTTP listener for the controlled Application Gateway demo"
      }
      gateway-manager-to-appgw-infrastructure = {
        nsg_key                    = "appgw"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["65200-65535"]
        source_address_prefix      = "GatewayManager"
        source_subnet_key          = null
        destination_subnet_key     = null
        destination_address_prefix = "*"
        description                = "Required Application Gateway v2 infrastructure communication"
      }
      appgw-subnet-internal = {
        nsg_key                    = "appgw"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "appgw"
        destination_subnet_key     = "appgw"
        destination_address_prefix = null
        description                = "Required communication between Application Gateway v2 instances"
      }
      appgw-to-apim-https = {
        nsg_key                    = "appgw"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["443"]
        source_address_prefix      = null
        source_subnet_key          = "appgw"
        destination_subnet_key     = "apim"
        destination_address_prefix = null
        description                = "Application Gateway forwarding to the internal API Management HTTPS gateway"
      }
      appgw-to-azure-dns = {
        nsg_key                    = "appgw"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["53"]
        source_address_prefix      = null
        source_subnet_key          = "appgw"
        destination_address_prefix = "AzurePlatformDNS"
        destination_subnet_key     = null
        description                = "Azure-provided DNS resolution required for the APIM backend hostname"
      }
      appgw-subnet-internal-egress = {
        nsg_key                    = "appgw"
        priority                   = 200
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "appgw"
        destination_subnet_key     = "appgw"
        destination_address_prefix = null
        description                = "Required communication between Application Gateway v2 instances"
      }
      deny-vnet-to-appgw = {
        nsg_key                    = "appgw"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = "VirtualNetwork"
        source_subnet_key          = null
        destination_subnet_key     = "appgw"
        destination_address_prefix = null
        description                = "Overrides Azure's default AllowVNetInBound after approved paths"
      }
      deny-appgw-to-vnet = {
        nsg_key                    = "appgw"
        priority                   = 4000
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "appgw"
        destination_address_prefix = "VirtualNetwork"
        destination_subnet_key     = null
        description                = "Overrides Azure's default AllowVNetOutBound after approved paths"
      }
    } : name => rule
    if var.enable_edge_stack
  }

  apim_nsg_rules = {
    for name, rule in {
      appgw-to-apim-gateway-https = {
        nsg_key                    = "apim"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["443"]
        source_address_prefix      = null
        source_subnet_key          = "appgw"
        destination_address_prefix = null
        destination_subnet_key     = "apim"
        description                = "Application Gateway access to the internal API Management gateway"
      }
      api-management-control-plane = {
        nsg_key                    = "apim"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["3443"]
        source_address_prefix      = "ApiManagement"
        source_subnet_key          = null
        destination_address_prefix = null
        destination_subnet_key     = "apim"
        description                = "Azure API Management control-plane access required for internal VNet mode"
      }
      azure-load-balancer-to-apim-infrastructure = {
        nsg_key                    = "apim"
        priority                   = 120
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["6390"]
        source_address_prefix      = "AzureLoadBalancer"
        source_subnet_key          = null
        destination_address_prefix = null
        destination_subnet_key     = "apim"
        description                = "Azure Load Balancer infrastructure probes required by API Management"
      }
      apim-subnet-internal = {
        nsg_key                    = "apim"
        priority                   = 200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = null
        destination_subnet_key     = "apim"
        description                = "Required communication between internal API Management instances"
      }
      apim-to-aks-backend-http = {
        nsg_key                    = "aks"
        priority                   = 210
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = null
        destination_subnet_key     = "aks"
        description                = "Internal API Management access to the AKS application load balancer"
      }
      apim-to-aks-backend-http-egress = {
        nsg_key                    = "apim"
        priority                   = 100
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = null
        destination_subnet_key     = "aks"
        description                = "API Management forwarding to the internal AKS application backend"
      }
      apim-to-internet-http = {
        nsg_key                    = "apim"
        priority                   = 110
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["80"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = "Internet"
        destination_subnet_key     = null
        description                = "API Management certificate validation and platform management over HTTP"
      }
      apim-to-storage-https = {
        nsg_key                    = "apim"
        priority                   = 120
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["443"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = "Storage"
        destination_subnet_key     = null
        description                = "API Management core dependency on Azure Storage"
      }
      apim-to-sql = {
        nsg_key                    = "apim"
        priority                   = 130
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["1433"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = "Sql"
        destination_subnet_key     = null
        description                = "API Management core dependency on Azure SQL"
      }
      apim-to-key-vault-https = {
        nsg_key                    = "apim"
        priority                   = 140
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["443"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = "AzureKeyVault"
        destination_subnet_key     = null
        description                = "API Management core dependency on Azure Key Vault"
      }
      apim-to-azure-monitor = {
        nsg_key                    = "apim"
        priority                   = 150
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["1886", "443"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = "AzureMonitor"
        destination_subnet_key     = null
        description                = "API Management diagnostics, metrics, and resource health"
      }
      apim-to-azure-dns = {
        nsg_key                    = "apim"
        priority                   = 160
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["53"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = "AzurePlatformDNS"
        destination_subnet_key     = null
        description                = "Azure-provided DNS resolution required by internal API Management"
      }
      apim-subnet-internal-egress = {
        nsg_key                    = "apim"
        priority                   = 200
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = null
        destination_subnet_key     = "apim"
        description                = "Required communication between internal API Management instances"
      }
      deny-vnet-to-apim = {
        nsg_key                    = "apim"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = "VirtualNetwork"
        source_subnet_key          = null
        destination_address_prefix = null
        destination_subnet_key     = "apim"
        description                = "Overrides Azure's default AllowVNetInBound after approved paths"
      }
      deny-apim-to-vnet = {
        nsg_key                    = "apim"
        priority                   = 4000
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "apim"
        destination_address_prefix = "VirtualNetwork"
        destination_subnet_key     = null
        description                = "Overrides Azure's default AllowVNetOutBound after approved paths"
      }
    } : name => rule
    if var.enable_apim
  }

  aks_nsg_rules = {
    for name, rule in {
      azure-load-balancer-to-aks-probes = {
        nsg_key                    = "aks"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["30000-32767"]
        source_address_prefix      = "AzureLoadBalancer"
        source_subnet_key          = null
        destination_address_prefix = null
        destination_subnet_key     = "aks"
        description                = "Azure Load Balancer health probes for AKS services"
      }
      aks-subnet-internal = {
        nsg_key                    = "aks"
        priority                   = 220
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "aks"
        destination_address_prefix = null
        destination_subnet_key     = "aks"
        description                = "Required AKS node and Azure CNI pod communication"
      }
      aks-to-private-endpoints-https = {
        nsg_key                    = "aks"
        priority                   = 190
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["443"]
        source_address_prefix      = null
        source_subnet_key          = "aks"
        destination_address_prefix = null
        destination_subnet_key     = "private-endpoints"
        description                = "AKS access to the Key Vault private endpoint"
      }
      aks-to-internet-https = {
        nsg_key                    = "aks"
        priority                   = 200
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["443"]
        source_address_prefix      = null
        source_subnet_key          = "aks"
        destination_address_prefix = "Internet"
        destination_subnet_key     = null
        description                = "AKS image pulls and required Azure HTTPS endpoints"
      }
      aks-to-azure-dns = {
        nsg_key                    = "aks"
        priority                   = 210
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["53"]
        source_address_prefix      = null
        source_subnet_key          = "aks"
        destination_address_prefix = "AzurePlatformDNS"
        destination_subnet_key     = null
        description                = "Azure-provided DNS resolution required by AKS and Key Vault private DNS"
      }
      aks-subnet-internal-egress = {
        nsg_key                    = "aks"
        priority                   = 220
        direction                  = "Outbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "aks"
        destination_address_prefix = null
        destination_subnet_key     = "aks"
        description                = "Required AKS node and Azure CNI pod communication"
      }
      deny-vnet-to-aks = {
        nsg_key                    = "aks"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = "VirtualNetwork"
        source_subnet_key          = null
        destination_address_prefix = null
        destination_subnet_key     = "aks"
        description                = "Overrides Azure's default AllowVNetInBound after APIM, management, probe, and AKS-internal paths"
      }
      deny-aks-to-vnet = {
        nsg_key                    = "aks"
        priority                   = 4000
        direction                  = "Outbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = null
        source_subnet_key          = "aks"
        destination_address_prefix = "VirtualNetwork"
        destination_subnet_key     = null
        description                = "Overrides Azure's default AllowVNetOutBound after approved paths"
      }
    } : name => rule
    if var.enable_aks_demo
  }

  private_endpoint_nsg_rules = {
    for name, rule in {
      aks-to-key-vault-private-endpoint = {
        nsg_key                    = "private-endpoints"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["443"]
        source_address_prefix      = null
        source_subnet_key          = "aks"
        destination_address_prefix = null
        destination_subnet_key     = "private-endpoints"
        description                = "AKS access to the Key Vault private endpoint over HTTPS"
      }
      deny-vnet-to-private-endpoints = {
        nsg_key                    = "private-endpoints"
        priority                   = 4000
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_ranges    = ["*"]
        source_address_prefix      = "VirtualNetwork"
        source_subnet_key          = null
        destination_address_prefix = null
        destination_subnet_key     = "private-endpoints"
        description                = "Overrides Azure's default AllowVNetInBound after approved private endpoint paths"
      }
    } : name => rule
    if var.enable_key_vault_private_endpoint
  }

  entra_group_role_assignments = {
    for name, assignment in {
      # Principal: optional platform administrators Entra group. Contributor is
      # limited to the foundation resource group for platform resource changes.
      platform-administrators = {
        scope_key            = "foundation"
        role_definition_name = "Contributor"
        principal_id         = var.platform_admin_group_object_id
        principal_type       = "Group"
        description          = "Platform administrators manage resources in the foundation resource group without managing access"
      }
      # Principal: optional network operators Entra group. Network Contributor
      # is limited to the network resource group for network administration.
      network-operators = {
        scope_key            = "network"
        role_definition_name = "Network Contributor"
        principal_id         = var.network_operator_group_object_id
        principal_type       = "Group"
        description          = "Network operators manage resources only in the network resource group"
      }
      # Principal: optional security readers Entra group. Security Reader is
      # limited to the security resource group for read-only security review.
      security-readers = {
        scope_key            = "security"
        role_definition_name = "Security Reader"
        principal_id         = var.security_reader_group_object_id
        principal_type       = "Group"
        description          = "Security readers inspect security posture without changing resources"
      }
    } : name => assignment
    if assignment.principal_id != null
  }

  protected_resource_group_locks = {
    for rg_key, lock in {
      network = {
        level = "CanNotDelete"
        notes = "Optional deletion protection for shared network resources"
      }
      security = {
        level = "CanNotDelete"
        notes = "Optional deletion protection for security resources"
      }
    } : rg_key => lock
    if var.enable_resource_group_locks
  }
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
    local.edge_nsg_rules,
    local.apim_nsg_rules,
    local.aks_nsg_rules,
    local.private_endpoint_nsg_rules
  )
}

module "security_baseline" {
  source = "../02-security-baseline"

  location                                = var.location
  project_name                            = var.project_name
  environment                             = var.environment
  owner                                   = var.owner
  tenant_id                               = var.tenant_id
  common_tags                             = module.foundation.common_tags
  enable_key_vault                        = var.enable_key_vault
  enable_key_vault_private_endpoint       = var.enable_key_vault_private_endpoint
  enable_key_vault_purge_protection       = var.enable_key_vault_purge_protection
  key_vault_public_network_access_enabled = var.key_vault_public_network_access_enabled
  private_endpoint_subnet_id              = var.enable_key_vault_private_endpoint ? module.networking.subnets["private-endpoints"].id : null
  virtual_network_id                      = var.enable_key_vault_private_endpoint ? module.networking.virtual_network.id : null
  key_vault_secrets_officer_principal_ids = toset(compact([var.key_vault_bootstrap_principal_object_id]))
  resource_groups                         = module.foundation.resource_groups
  role_assignments                        = merge(var.role_assignments, local.entra_group_role_assignments)
  resource_group_locks                    = merge(var.resource_group_locks, local.protected_resource_group_locks)
}

module "workloads" {
  source = "../04-workloads"

  location               = module.foundation.location
  project_name           = var.project_name
  environment            = var.environment
  resource_group_name    = module.foundation.resource_groups.foundation.name
  common_tags            = module.foundation.common_tags
  enable_aks_demo        = var.enable_aks_demo
  enable_key_vault       = var.enable_key_vault
  key_vault_id           = var.enable_key_vault ? module.security_baseline.key_vault.id : null
  aks_subnet_id          = module.networking.subnets["aks"].id
  aks_node_count         = var.aks_node_count
  aks_node_vm_size       = var.aks_node_vm_size
  application_backend_ip = var.aks_internal_load_balancer_ip
  tenant_id              = var.tenant_id
  cluster_admin_principal_ids = toset(compact([
    var.platform_admin_group_object_id,
    var.aks_deployer_principal_object_id
  ]))
  api_server_authorized_ip_ranges = var.aks_api_server_authorized_ip_ranges
  automatic_upgrade_channel       = var.aks_automatic_upgrade_channel
  node_os_upgrade_channel         = var.aks_node_os_upgrade_channel
}

resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  count = var.enable_aks_demo ? 1 : 0

  # Principal: AKS system-assigned control-plane identity.
  # Scope/purpose: Network Contributor on the AKS subnet so the Azure cloud
  # provider can create and manage the application's internal LoadBalancer.
  scope                            = module.networking.subnets["aks"].id
  role_definition_name             = "Network Contributor"
  principal_id                     = module.workloads.aks_cluster.identity_principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

module "apim" {
  source = "../05-apim"

  location            = module.foundation.location
  resource_group_name = module.foundation.resource_groups.network.name
  project_name        = var.project_name
  environment         = var.environment
  owner               = var.owner
  tags                = module.foundation.common_tags
  enable_apim         = var.enable_apim
  apim_sku_name       = var.apim_sku_name
  apim_subnet_id      = module.networking.subnets["apim"].id
  virtual_network_id  = module.networking.virtual_network.id
  backend_url         = module.workloads.application_backend_url
  openapi_spec_path   = "${path.root}/../../app/openapi.yaml"

  depends_on = [module.networking]
}

module "edge" {
  source = "../03-edge"

  location                  = module.foundation.location
  project_name              = var.project_name
  environment               = var.environment
  resource_group_name       = module.foundation.resource_groups.network.name
  common_tags               = module.foundation.common_tags
  enable_edge_stack         = var.enable_edge_stack
  app_gateway_subnet_id     = module.networking.subnets["appgw"].id
  waf_policy_mode           = var.waf_policy_mode
  apim_backend_enabled      = var.enable_apim
  apim_backend_ip_addresses = var.enable_apim ? module.apim.apim.private_ip_addresses : []
  apim_gateway_hostname     = var.enable_apim ? module.apim.apim.gateway_hostname : null

  depends_on = [module.networking, module.apim]
}
