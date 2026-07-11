output "role_assignments" {
  description = "Created RBAC assignments keyed by logical assignment name"
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
  description = "Created management locks keyed by resource group logical name"
  value = {
    for rg_key, lock in azurerm_management_lock.resource_group : rg_key => {
      id         = lock.id
      scope      = lock.scope
      lock_level = lock.lock_level
      notes      = lock.notes
    }
  }
}
