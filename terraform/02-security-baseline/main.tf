locals {
  key_vault_name = "kv-${var.project_name}-${var.environment}-${var.owner}"
}

resource "azurerm_role_assignment" "landing_zone" {
  for_each = var.role_assignments

  # Principal, role, scope, and purpose are supplied by the validated map. The
  # root module's standard assignments target Entra groups at resource-group
  # scope; this resource never expands their scope to the subscription.
  scope                = var.resource_groups[each.value.scope_key].id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
  principal_type       = try(each.value.principal_type, null)
  description          = try(each.value.description, null)
}

resource "azurerm_management_lock" "resource_group" {
  for_each = var.resource_group_locks

  name       = "lock-${each.key}"
  scope      = var.resource_groups[each.key].id
  lock_level = each.value.level
  notes      = each.value.notes
}

resource "azurerm_key_vault" "main" {
  count = var.enable_key_vault ? 1 : 0

  name                          = local.key_vault_name
  location                      = var.location
  resource_group_name           = var.resource_groups["security"].name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = var.enable_key_vault_purge_protection
  public_network_access_enabled = var.enable_key_vault_private_endpoint ? false : var.key_vault_public_network_access_enabled
  tags                          = var.common_tags

  lifecycle {
    precondition {
      condition     = !var.enable_key_vault_private_endpoint || (!var.key_vault_public_network_access_enabled && var.private_endpoint_subnet_id != null && var.virtual_network_id != null)
      error_message = "A Key Vault private endpoint requires public access disabled and valid subnet and VNet IDs."
    }
  }
}

resource "azurerm_role_assignment" "key_vault_secrets_officer" {
  for_each = var.enable_key_vault ? var.key_vault_secrets_officer_principal_ids : toset([])

  scope                = azurerm_key_vault.main[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = each.value
}

resource "azurerm_private_dns_zone" "key_vault" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_groups["network"].name
  tags                = var.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                  = "link-key-vault-${var.project_name}-${var.environment}"
  resource_group_name   = var.resource_groups["network"].name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.common_tags
}

resource "azurerm_private_endpoint" "key_vault" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                = "pe-${local.key_vault_name}"
  location            = var.location
  resource_group_name = var.resource_groups["network"].name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.common_tags

  private_service_connection {
    name                           = "psc-${local.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.main[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "key-vault"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.key_vault]
}
