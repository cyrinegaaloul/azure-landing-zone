output "apim" {
  description = "API Management details, or null when APIM is disabled."
  value = var.enable_apim ? {
    id                   = azurerm_api_management.this[0].id
    name                 = azurerm_api_management.this[0].name
    gateway_url          = azurerm_api_management.this[0].gateway_url
    gateway_hostname     = local.endpoint_hostnames.gateway
    private_ip_addresses = azurerm_api_management.this[0].private_ip_addresses
    api_name             = azurerm_api_management_api.this[0].name
    backend_url          = var.backend_url
    p4d_api_name         = var.p4d_backend_url != null ? azurerm_api_management_api.p4d_backend[0].name : null
    p4d_backend_url      = var.p4d_backend_url
  } : null
}
