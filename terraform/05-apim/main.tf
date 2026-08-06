locals {
  apim_name = "apim-${var.project_name}-${var.environment}-${var.owner}"
  api_name  = "landing-zone-demo-api"

  endpoint_hostnames = {
    gateway          = "${local.apim_name}.azure-api.net"
    portal           = "${local.apim_name}.portal.azure-api.net"
    developer_portal = "${local.apim_name}.developer.azure-api.net"
    management       = "${local.apim_name}.management.azure-api.net"
    scm              = "${local.apim_name}.scm.azure-api.net"
  }

  enabled_endpoint_hostnames = var.enable_apim ? local.endpoint_hostnames : {}
}

resource "azurerm_api_management" "this" {
  count = var.enable_apim ? 1 : 0

  name                 = local.apim_name
  location             = var.location
  resource_group_name  = var.resource_group_name
  publisher_name       = var.publisher_name
  publisher_email      = var.publisher_email
  sku_name             = var.apim_sku_name
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id = var.apim_subnet_id
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "apim_endpoint" {
  for_each = local.enabled_endpoint_hostnames

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "apim_endpoint" {
  for_each = local.enabled_endpoint_hostnames

  name                  = "link-${replace(each.key, "_", "-")}-${var.project_name}-${var.environment}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.apim_endpoint[each.key].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_a_record" "apim_endpoint" {
  for_each = local.enabled_endpoint_hostnames

  name                = "@"
  zone_name           = azurerm_private_dns_zone.apim_endpoint[each.key].name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = azurerm_api_management.this[0].private_ip_addresses
  tags                = var.tags
}

resource "azurerm_api_management_api" "this" {
  count = var.enable_apim ? 1 : 0

  name                  = local.api_name
  resource_group_name   = var.resource_group_name
  api_management_name   = azurerm_api_management.this[0].name
  revision              = "1"
  display_name          = "Landing Zone Demo API"
  path                  = "demo"
  protocols             = ["http", "https"]
  service_url           = var.backend_url
  subscription_required = false

  import {
    content_format = "openapi"
    content_value  = file(var.openapi_spec_path)
  }
}

resource "azurerm_api_management_api_policy" "this" {
  count = var.enable_apim ? 1 : 0

  api_name            = azurerm_api_management_api.this[0].name
  api_management_name = azurerm_api_management.this[0].name
  resource_group_name = var.resource_group_name

  xml_content = <<-XML
    <policies>
      <inbound>
        <base />
        <rate-limit-by-key calls="30" renewal-period="60" counter-key="@(context.Request.IpAddress)" />
        <set-header name="X-Correlation-ID" exists-action="skip">
          <value>@(context.RequestId.ToString())</value>
        </set-header>
      </inbound>
      <backend>
        <forward-request />
      </backend>
      <outbound>
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
}
