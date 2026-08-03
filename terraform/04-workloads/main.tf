locals {
  aks_cluster_name = "aks-${var.project_name}-${var.environment}"
  aks_dns_prefix   = "aks${replace(var.project_name, "-", "")}${var.environment}"
}

resource "azurerm_kubernetes_cluster" "aks" {
  count = var.enable_aks_demo ? 1 : 0

  name                = local.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = local.aks_dns_prefix
  sku_tier            = "Free"

  default_node_pool {
    name           = "system"
    node_count     = var.aks_node_count
    vm_size        = var.aks_node_vm_size
    vnet_subnet_id = var.aks_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = var.common_tags
}
