locals {
  aks_cluster_name           = "aks-${var.project_name}-${var.environment}"
  aks_dns_prefix             = "aks${replace(var.project_name, "-", "")}${var.environment}"
  workload_identity_name     = "id-app-${var.project_name}-${var.environment}"
  kubernetes_namespace       = "demo"
  kubernetes_service_account = "landing-zone-demo"
}

resource "azurerm_kubernetes_cluster" "aks" {
  count = var.enable_aks_demo ? 1 : 0

  name                      = local.aks_cluster_name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  dns_prefix                = local.aks_dns_prefix
  sku_tier                  = "Free"
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name           = "system"
    node_count     = var.aks_node_count
    vm_size        = var.aks_node_vm_size
    vnet_subnet_id = var.aks_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = var.common_tags
}

resource "azurerm_user_assigned_identity" "app" {
  count = var.enable_aks_demo ? 1 : 0

  name                = local.workload_identity_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_federated_identity_credential" "app" {
  count = var.enable_aks_demo ? 1 : 0

  name                      = "fic-${local.kubernetes_service_account}"
  user_assigned_identity_id = azurerm_user_assigned_identity.app[0].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.aks[0].oidc_issuer_url
  subject                   = "system:serviceaccount:${local.kubernetes_namespace}:${local.kubernetes_service_account}"
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  count = var.enable_aks_demo && var.enable_key_vault ? 1 : 0

  # Principal: application user-assigned managed identity federated to the
  # demo ServiceAccount. Scope/purpose: Key Vault Secrets User on this vault
  # only, allowing the CSI provider to read secret values for the pod.
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app[0].principal_id
  principal_type       = "ServicePrincipal"
}
