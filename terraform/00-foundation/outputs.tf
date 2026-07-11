output "resource_groups" {
  description = "Created resource groups with names and IDs for downstream modules"
  value = {
    foundation = {
      name = azurerm_resource_group.foundation.name
      id   = azurerm_resource_group.foundation.id
    }
    network = {
      name = azurerm_resource_group.network.name
      id   = azurerm_resource_group.network.id
    }
    security = {
      name = azurerm_resource_group.security.name
      id   = azurerm_resource_group.security.id
    }
  }
}

output "location" {
  description = "Azure region used by the foundation module"
  value       = var.location
}

output "name_prefix" {
  description = "Standardized name prefix reused by future landing zone modules"
  value       = local.name_prefix
}

output "common_tags" {
  description = "Resolved tags applied to the landing zone foundation resources"
  value       = local.common_tags
}
