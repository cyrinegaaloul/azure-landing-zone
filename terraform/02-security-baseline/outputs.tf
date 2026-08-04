output "role_assignments" {
  value = {
    for assignment_name, assignment in azurerm_role_assignment.landing_zone : assignment_name => {
      id                   = assignment.id
      scope                = assignment.scope
      role_definition_name = assignment.role_definition_name
      principal_id         = assignment.principal_id
    }
  }
}

output "resource_group_locks" {
  value = {
    for rg_key, lock in azurerm_management_lock.resource_group : rg_key => {
      id         = lock.id
      scope      = lock.scope
      lock_level = lock.lock_level
      notes      = lock.notes
    }
  }
}

output "key_vault" {
  description = "Key Vault details when enabled, otherwise null"
  value = var.enable_key_vault ? {
    name      = azurerm_key_vault.main[0].name
    id        = azurerm_key_vault.main[0].id
    vault_uri = azurerm_key_vault.main[0].vault_uri
  } : null
}
