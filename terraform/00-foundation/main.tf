locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    project     = "azure-landing-zone"
    environment = var.environment
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    criticality = var.criticality
    workload    = var.workload_name
  }

  common_tags = merge(local.default_tags, var.additional_tags)

  resource_group_names = {
    foundation = join("-", ["rg", var.resource_group_names.foundation, local.name_prefix])
    network    = join("-", ["rg", var.resource_group_names.network, local.name_prefix])
    security   = join("-", ["rg", var.resource_group_names.security, local.name_prefix])
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
