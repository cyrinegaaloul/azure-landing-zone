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

  # Enable NSG evaluation for the dedicated private-endpoints subnet so its
  # application-path rule is visible and enforceable alongside Azure defaults.
  private_endpoint_network_policies = each.key == "private-endpoints" ? "NetworkSecurityGroupEnabled" : "Disabled"
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

resource "azurerm_network_security_rule" "landing_zone" {
  for_each = var.nsg_rules

  name                         = each.key
  priority                     = each.value.priority
  direction                    = each.value.direction
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_range            = each.value.source_port_range
  destination_port_ranges      = each.value.destination_port_ranges
  source_address_prefix        = each.value.source_subnet_key == null ? each.value.source_address_prefix : null
  source_address_prefixes      = each.value.source_subnet_key == null ? null : try(var.subnets[each.value.source_subnet_key].address_prefixes, [])
  destination_address_prefix   = each.value.destination_subnet_key == null ? each.value.destination_address_prefix : null
  destination_address_prefixes = each.value.destination_subnet_key == null ? null : try(var.subnets[each.value.destination_subnet_key].address_prefixes, [])
  resource_group_name          = var.resource_group_name
  network_security_group_name  = try(azurerm_network_security_group.landing_zone[each.value.nsg_key].name, "invalid-nsg-key")
  description                  = each.value.description

  lifecycle {
    precondition {
      condition     = contains(keys(azurerm_network_security_group.landing_zone), each.value.nsg_key)
      error_message = "NSG rule ${each.key} targets an unknown subnet NSG key."
    }

    precondition {
      condition = (
        (each.value.source_subnet_key == null || contains(keys(var.subnets), each.value.source_subnet_key)) &&
        (each.value.destination_subnet_key == null || contains(keys(var.subnets), each.value.destination_subnet_key))
      )
      error_message = "NSG rule ${each.key} references an unknown source or destination subnet key."
    }
  }
}
