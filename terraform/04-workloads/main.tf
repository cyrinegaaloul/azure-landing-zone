locals {
  name_prefix = "${var.project_name}-${var.environment}"

  planned_workloads = {
    aks = {
      enabled         = var.enable_aks_demo
      subnet_name     = var.aks_subnet_name
      cluster_tier    = "Free"
      node_pool_size  = "smallest_for_demo"
      billing_model   = "underlying_compute_billed"
      deployment_mode = var.enable_aks_demo ? "demo" : "deferred"
    }
    jelastic_p4d = {
      enabled         = var.enable_jelastic_demo
      deployment_mode = var.enable_jelastic_demo ? "demo" : "deferred"
      application     = var.application_name
      billing_model   = "external_or_service_specific"
    }
    application = {
      name            = var.application_name
      image           = var.container_image_name
      port            = var.container_port
      namespace       = var.kubernetes_namespace
      deployment_mode = (var.enable_aks_demo || var.enable_jelastic_demo) ? "demo" : "local_only"
    }
  }
}
