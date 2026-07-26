locals {
  name_prefix = "${var.project_name}-${var.environment}"

  planned_observability = {
    prometheus = {
      enabled       = var.enable_observability_demo
      mode          = var.prometheus_mode
      billing_model = var.prometheus_mode == "azure-monitor-managed" ? "consumption_based_ingestion" : "workload_compute_billed"
    }
    grafana = {
      enabled       = var.enable_observability_demo
      mode          = var.grafana_mode
      billing_model = var.grafana_mode == "azure-managed" ? "continuously_billed" : "included_in_selected_runtime"
    }
  }
}
