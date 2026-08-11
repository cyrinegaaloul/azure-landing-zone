output "virtual_network" {
  value = {
    name          = azurerm_virtual_network.landing_zone.name
    id            = azurerm_virtual_network.landing_zone.id
    address_space = azurerm_virtual_network.landing_zone.address_space
  }
}

output "subnets" {
  value = {
    for subnet_name, subnet in azurerm_subnet.landing_zone : subnet_name => {
      name             = subnet.name
      id               = subnet.id
      address_prefixes = subnet.address_prefixes
    }
  }
}
