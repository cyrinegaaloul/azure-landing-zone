locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    project      = "azure-landing-zone"
    environment  = var.environment
    owner        = var.owner
    cost_center  = var.cost_center
    managed_by   = "terraform"
    criticality  = "low"
    workload     = "landing-zone"
  }
}

resource "azurerm_resource_group" "foundation" {
  name = join(
    "-",
    [
      "rg",
      var.resource_group_names.foundation,
      local.name_prefix
    ]
  )

  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "network" {
  name = join(
    "-",
    [
      "rg",
      var.resource_group_names.network,
      local.name_prefix
    ]
  )

  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "security" {
  name = join(
    "-",
    [
      "rg",
      var.resource_group_names.security,
      local.name_prefix
    ]
  )

  location = var.location
  tags     = local.common_tags
}