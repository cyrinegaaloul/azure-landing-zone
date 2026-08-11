output "key_vault" {
  description = "Key Vault details when enabled, otherwise null"
  value = var.enable_key_vault ? {
    name                  = azurerm_key_vault.main[0].name
    id                    = azurerm_key_vault.main[0].id
    vault_uri             = azurerm_key_vault.main[0].vault_uri
    private_endpoint_id   = var.enable_key_vault_private_endpoint ? azurerm_private_endpoint.key_vault[0].id : null
    private_dns_zone_name = var.enable_key_vault_private_endpoint ? azurerm_private_dns_zone.key_vault[0].name : null
  } : null
}
