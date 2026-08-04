locals {
  name_prefix               = "${var.project_name}-${var.environment}"
  application_gateway_name  = "appgw-${local.name_prefix}"
  public_ip_name            = "pip-appgw-${local.name_prefix}"
  waf_policy_name           = "wafpol-${local.name_prefix}"
  gateway_ip_configuration  = "appgw-ipconfig-${local.name_prefix}"
  frontend_ip_configuration = "appgw-public-frontend-${local.name_prefix}"
  frontend_port             = "appgw-http-port-${local.name_prefix}"
  backend_address_pool      = "appgw-bootstrap-pool-${local.name_prefix}"
  backend_http_settings     = "appgw-bootstrap-http-${local.name_prefix}"
  health_probe              = "appgw-bootstrap-health-${local.name_prefix}"
  http_listener             = "appgw-bootstrap-http-listener-${local.name_prefix}"
  request_routing_rule      = "appgw-bootstrap-http-rule-${local.name_prefix}"
}

resource "azurerm_public_ip" "application_gateway" {
  count = var.enable_edge_stack ? 1 : 0

  name                = local.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.common_tags
}

resource "azurerm_web_application_firewall_policy" "application_gateway" {
  count = var.enable_edge_stack ? 1 : 0

  name                = local.waf_policy_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags

  policy_settings {
    enabled = true
    mode    = var.waf_policy_mode
  }

  managed_rules {
    managed_rule_set {
      type    = "Microsoft_DefaultRuleSet" # Microsoft-managed OWASP-based rules
      version = "2.2"
    }
  }
}

resource "azurerm_application_gateway" "main" {
  count = var.enable_edge_stack ? 1 : 0

  name                              = local.application_gateway_name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  firewall_policy_id                = azurerm_web_application_firewall_policy.application_gateway[0].id
  force_firewall_policy_association = true
  tags                              = var.common_tags

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = var.application_gateway_capacity
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration
    subnet_id = var.app_gateway_subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration
    public_ip_address_id = azurerm_public_ip.application_gateway[0].id
  }

  # Bootstrap-only HTTP configuration. AGIC replaces and manages these sets
  # after the Kubernetes Ingress is created.
  frontend_port {
    name = local.frontend_port
    port = 80
  }

  backend_address_pool {
    name = local.backend_address_pool
  }

  probe {
    name                = local.health_probe
    protocol            = "Http"
    path                = var.health_probe_path
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3
  }

  backend_http_settings {
    name                  = local.backend_http_settings
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = local.health_probe
  }

  http_listener {
    name                           = local.http_listener
    frontend_ip_configuration_name = local.frontend_ip_configuration
    frontend_port_name             = local.frontend_port
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener
    backend_address_pool_name  = local.backend_address_pool
    backend_http_settings_name = local.backend_http_settings
  }

  lifecycle {
    # AGIC owns these child configurations after Kubernetes Ingress is applied.
    ignore_changes = [
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      redirect_configuration,
      request_routing_rule,
      rewrite_rule_set,
      url_path_map
    ]
  }
}
