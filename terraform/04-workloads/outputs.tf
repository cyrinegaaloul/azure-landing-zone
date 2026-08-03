output "aks_cluster" {
  description = "AKS cluster details when enabled"
  value = var.enable_aks_demo ? {
    name = azurerm_kubernetes_cluster.aks[0].name
    id   = azurerm_kubernetes_cluster.aks[0].id
    fqdn = azurerm_kubernetes_cluster.aks[0].fqdn
  } : null
}
