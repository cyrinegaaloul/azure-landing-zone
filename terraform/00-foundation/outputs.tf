output "resource_groups" {
  description = "Created resource groups"
  value = {
    foundation = azurerm_resource_group.foundation.name
    network    = azurerm_resource_group.network.name
    security   = azurerm_resource_group.security.name
  }
}