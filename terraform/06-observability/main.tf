locals {
  monitor_workspace_name = "amw-${var.project_name}-${var.environment}"
  grafana_name           = "amg-${var.project_name}-${var.environment}"
}

resource "azurerm_monitor_workspace" "this" {
  count = var.enabled ? 1 : 0

  name                = local.monitor_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_dashboard_grafana" "this" {
  count = var.enabled ? 1 : 0

  name                          = local.grafana_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  api_key_enabled               = false
  public_network_access_enabled = true
  grafana_major_version         = "12"
  sku                           = "Standard"

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.this[0].id
  }

  tags = var.common_tags
}

# Scoped only to the workspace: Grafana can query managed Prometheus data but
# receives no permissions on the subscription or the AKS cluster.
resource "azurerm_role_assignment" "grafana_monitoring_data_reader" {
  count = var.enabled ? 1 : 0

  scope                = azurerm_monitor_workspace.this[0].id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.this[0].identity[0].principal_id
  principal_type       = "ServicePrincipal"
}
