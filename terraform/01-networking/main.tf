locals {
  name_prefix = "${var.project_name}-${var.environment}"
  vnet_name   = "vnet-${var.project_name}-${var.environment}"

  subnet_config = {
    for subnet_name, subnet in var.subnets : subnet_name => merge(
      subnet,
      {
        subnet_resource_name = "snet-${subnet_name}-${local.name_prefix}"
        nsg_resource_name    = "nsg-${subnet_name}-${local.name_prefix}"
      }
    )
  }
}

resource "azurerm_virtual_network" "landing_zone" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.common_tags
}

resource "azurerm_subnet" "landing_zone" {
  for_each = local.subnet_config

  name                 = each.value.subnet_resource_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.landing_zone.name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_network_security_group" "landing_zone" {
  for_each = {
    for subnet_name, subnet in local.subnet_config : subnet_name => subnet
    if subnet.create_nsg
  }

  name                = each.value.nsg_resource_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags
}

resource "azurerm_subnet_network_security_group_association" "landing_zone" {
  for_each = azurerm_network_security_group.landing_zone

  subnet_id                 = azurerm_subnet.landing_zone[each.key].id
  network_security_group_id = each.value.id
}
