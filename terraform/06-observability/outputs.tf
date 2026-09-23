output "azure_monitor_workspace" {
  value = var.enabled ? {
    name = azurerm_monitor_workspace.this[0].name
    id   = azurerm_monitor_workspace.this[0].id
  } : null
}

output "managed_grafana" {
  value = var.enabled ? {
    name     = azurerm_dashboard_grafana.this[0].name
    id       = azurerm_dashboard_grafana.this[0].id
    endpoint = azurerm_dashboard_grafana.this[0].endpoint
  } : null
}

output "resources" {
  value = var.enabled ? {
    azure_monitor_workspace = {
      name = azurerm_monitor_workspace.this[0].name
      id   = azurerm_monitor_workspace.this[0].id
    }
    managed_grafana = {
      name     = azurerm_dashboard_grafana.this[0].name
      id       = azurerm_dashboard_grafana.this[0].id
      endpoint = azurerm_dashboard_grafana.this[0].endpoint
    }
  } : null
}
