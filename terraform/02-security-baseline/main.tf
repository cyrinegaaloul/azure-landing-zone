resource "azurerm_role_assignment" "landing_zone" {
  for_each = var.role_assignments

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
