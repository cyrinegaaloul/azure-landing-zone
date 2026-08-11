locals {
  resource_group_name  = "rg-tfstate-${var.project_name}-${var.environment}"
  storage_account_name = "st${replace(var.project_name, "-", "")}${var.environment}${replace(var.owner, "-", "")}tfstate"
  backend_state_key    = "development/azure-landing-zone.tfstate"
  common_tags          = merge(var.tags, { environment = var.environment })

  github_oidc_subjects = {
    demo-plan  = "repo:cyrinegaaloul/azure-landing-zone:environment:demo-plan"
    demo-apply = "repo:cyrinegaaloul/azure-landing-zone:environment:demo-apply"
  }

  subscription_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}

data "azurerm_client_config" "current" {} //Discover the currently logged-in Azure identity

resource "azurerm_user_assigned_identity" "github_actions" {
  name                = "id-github-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.state.location
  resource_group_name = azurerm_resource_group.state.name
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "github_actions" {
  for_each = local.github_oidc_subjects

  name                      = each.key
  user_assigned_identity_id = azurerm_user_assigned_identity.github_actions.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = each.value
}

resource "azurerm_resource_group" "state" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# trivy:ignore:AVD-AZU-0012 -- GitHub-hosted OIDC runners require a reachable Blob endpoint. Anonymous container access and shared-key authentication are disabled; Blob access requires Entra ID and scoped RBAC.
resource "azurerm_storage_account" "state" {
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS" //locally redundant storage
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2" //traffic protection
  shared_access_key_enabled       = false    //no shared access keys, use azure entra id auth
  public_network_access_enabled   = true     //github actions runners need to reach the blob endpoint
  allow_nested_items_to_be_public = false    //no public access to blob containers
  tags                            = local.common_tags

  blob_properties {
    versioning_enabled = true //keep previous versions of state files for recovery

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  lifecycle {
    prevent_destroy = true //prevent accidental deletion

    precondition {
      condition     = length(local.storage_account_name) >= 3 && length(local.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", local.storage_account_name))
      error_message = "The generated storage account name must contain 3-24 lowercase letters and numbers."
    }
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private" //no public access to data

  depends_on = [azurerm_role_assignment.current_user_state_blob_contributor]
}

resource "azurerm_role_assignment" "github_state_blob_contributor" {
  scope                            = azurerm_storage_account.state.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.github_actions.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "current_user_state_blob_contributor" {
  count = var.grant_current_user_backend_access ? 1 : 0

  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}

resource "azurerm_role_assignment" "github_deployment" {
  for_each = toset([
    "Contributor",
    "Role Based Access Control Administrator"
  ])

  # The root creates its three resource groups and role assignments inside
  # them. Subscription scope is therefore the narrowest scope that exists
  # before the first deployment and covers every Terraform-managed target.
  scope                            = local.subscription_scope
  role_definition_name             = each.value
  principal_id                     = azurerm_user_assigned_identity.github_actions.principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}
