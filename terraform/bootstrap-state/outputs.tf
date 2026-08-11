output "backend" {
  description = "Non-secret values used by the root azurerm backend"
  value = {
    resource_group_name  = azurerm_resource_group.state.name
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
    key                  = local.backend_state_key
  }
}

output "backend_resource_group_name" {
  description = "Resource group containing the Terraform state backend"
  value       = azurerm_resource_group.state.name
}

output "backend_storage_account_name" {
  description = "Storage account containing the Terraform state"
  value       = azurerm_storage_account.state.name
}

output "backend_container_name" {
  description = "Private blob container containing the Terraform state"
  value       = azurerm_storage_container.state.name
}

output "backend_state_key" {
  description = "Environment-specific root Terraform state key"
  value       = local.backend_state_key
}

output "github_oidc_client_id" {
  description = "Client ID copied once to the GitHub AZURE_CLIENT_ID secret"
  value       = azuread_application.github_actions.client_id
}

output "github_service_principal_object_id" {
  description = "GitHub deployment service principal object ID used for troubleshooting and AKS RBAC configuration"
  value       = azuread_service_principal.github_actions.object_id
}

output "tenant_id" {
  description = "Tenant ID copied once to the GitHub AZURE_TENANT_ID secret"
  value       = data.azurerm_client_config.current.tenant_id
}

output "subscription_id" {
  description = "Subscription ID copied once to the GitHub AZURE_SUBSCRIPTION_ID secret"
  value       = data.azurerm_client_config.current.subscription_id
}
