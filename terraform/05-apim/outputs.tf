output "apim" {
  description = "API Management details, or null when APIM is disabled."
  value = var.enable_apim ? {
    id          = azurerm_api_management.this[0].id
    name        = azurerm_api_management.this[0].name
    gateway_url = azurerm_api_management.this[0].gateway_url
    api_name    = azurerm_api_management_api.this[0].name
    backend_url = var.backend_url
  } : null
}
