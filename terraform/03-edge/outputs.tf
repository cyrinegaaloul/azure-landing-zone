output "edge" {
  description = "Conditional edge resource details"
  value = var.enable_edge_stack ? {
    application_gateway = {
      name = azurerm_application_gateway.main[0].name
      id   = azurerm_application_gateway.main[0].id
    }
    public_ip = {
      id      = azurerm_public_ip.application_gateway[0].id
      address = azurerm_public_ip.application_gateway[0].ip_address
    }
    waf_policy = {
      name = azurerm_web_application_firewall_policy.application_gateway[0].name
      id   = azurerm_web_application_firewall_policy.application_gateway[0].id
      mode = var.waf_policy_mode
    }
  } : null
}

