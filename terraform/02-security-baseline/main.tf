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
  public_network_access_enabled = var.key_vault_public_network_access_enabled
  tags                          = var.common_tags

  # Private networking remains deferred to a future approved deployment stage.
}
