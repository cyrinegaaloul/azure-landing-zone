output "virtual_network" {
  description = "Landing zone virtual network details"
  value = {
    name          = azurerm_virtual_network.landing_zone.name
    id            = azurerm_virtual_network.landing_zone.id
    address_space = azurerm_virtual_network.landing_zone.address_space
  }
}

output "subnets" {
  description = "Created subnet details keyed by logical subnet name"
  value = {
    for subnet_name, subnet in azurerm_subnet.landing_zone : subnet_name => {
      name             = subnet.name
      id               = subnet.id
      address_prefixes = subnet.address_prefixes
    }
  }
}

output "network_security_groups" {
  description = "Created network security groups keyed by logical subnet name"
  value = {
    for subnet_name, nsg in azurerm_network_security_group.landing_zone : subnet_name => {
      name = nsg.name
      id   = nsg.id
    }
  }
}

output "name_prefix" {
  description = "Standardized name prefix reused by future landing zone modules"
  value       = local.name_prefix
}
