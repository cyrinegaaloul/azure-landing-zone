output "aks_cluster" {
  description = "AKS cluster information"

  value = var.enable_aks_demo ? {
    name                  = azurerm_kubernetes_cluster.aks[0].name
    id                    = azurerm_kubernetes_cluster.aks[0].id
    fqdn                  = azurerm_kubernetes_cluster.aks[0].fqdn
    identity_principal_id = azurerm_kubernetes_cluster.aks[0].identity[0].principal_id
  } : null
}

output "workload_identity" {
  description = "Application workload identity details when AKS is enabled, otherwise null"
  sensitive   = true

  value = var.enable_aks_demo ? {
    name            = azurerm_user_assigned_identity.app[0].name
    id              = azurerm_user_assigned_identity.app[0].id
    client_id       = azurerm_user_assigned_identity.app[0].client_id
    principal_id    = azurerm_user_assigned_identity.app[0].principal_id
    service_account = local.kubernetes_service_account
    namespace       = local.kubernetes_namespace
  } : null
}

output "key_vault_role_assignment_id" {
  description = "Key Vault Secrets User role assignment ID when AKS and Key Vault are enabled, otherwise null"
  value       = var.enable_aks_demo && var.enable_key_vault ? azurerm_role_assignment.key_vault_secrets_user[0].id : null
}

output "application_backend_url" {
  description = "Internal AKS LoadBalancer URL used by API Management when AKS is enabled"
  value       = var.enable_aks_demo ? "http://${var.application_backend_ip}" : null

  depends_on = [azurerm_kubernetes_cluster.aks]
}
