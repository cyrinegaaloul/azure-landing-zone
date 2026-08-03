locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    project     = "azure-landing-zone"
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
  }

  resource_group_names = {
    foundation = "rg-foundation-${local.name_prefix}"
    network    = "rg-network-${local.name_prefix}"
    security   = "rg-security-${local.name_prefix}"
  }
}

resource "azurerm_resource_group" "foundation" {
  name     = local.resource_group_names.foundation
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "network" {
  name     = local.resource_group_names.network
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "security" {
  name     = local.resource_group_names.security
  location = var.location
  tags     = local.common_tags
}
