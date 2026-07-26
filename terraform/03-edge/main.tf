locals {
  name_prefix = "${var.project_name}-${var.environment}"

  planned_resources = {
    application_gateway = {
      enabled        = var.enable_edge_stack
      subnet_name    = var.app_gateway_subnet_name
      planned_sku    = "WAF_v2"
      billing_model  = "continuously_billed"
      deployment_day = var.edge_mode
    }
    waf = {
      enabled       = var.enable_edge_stack
      mode          = var.waf_policy_mode
      billing_model = "bundled_with_application_gateway"
    }
    api_management = {
      enabled       = var.enable_edge_stack
      subnet_name   = var.apim_subnet_name
      planned_tier  = var.apim_tier
      billing_model = "pay_per_use_or_tier_based"
    }
  }
}
