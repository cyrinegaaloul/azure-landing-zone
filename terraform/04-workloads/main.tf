locals {
  name_prefix      = "${var.project_name}-${var.environment}"
  aks_cluster_name = coalesce(var.aks_cluster_name_override, "aks-${local.name_prefix}")

  aks_cluster_plan = {
    enabled          = var.enable_aks_demo
    cluster_name     = local.aks_cluster_name
    subnet_name      = var.aks_subnet_name
    cluster_tier     = "Free"
    node_vm_size     = var.aks_node_vm_size
    node_count       = var.aks_node_count
    billing_model    = "underlying_compute_billed"
    ingress_strategy = var.ingress_strategy
    service_type     = var.kubernetes_service_type
    deployment_mode  = var.enable_aks_demo ? "enabled" : "deferred"
    rationale        = "Primary cloud-native runtime target"
  }

  application_plan = {
    name              = var.application_name
    image             = var.container_image_name
    registry_mode     = var.container_registry_mode
    registry_server   = var.container_registry_server
    image_pull_secret = var.image_pull_secret_name
    port              = var.container_port
    namespace         = var.kubernetes_namespace
    replica_count     = var.application_replica_count
    service_type      = var.kubernetes_service_type
    deployment_mode   = (var.enable_aks_demo || var.enable_jelastic_demo) ? "planned-platform-target" : "local_only"
    health_endpoint   = "/health"
    metrics_endpoint  = "/metrics"
    config_mode       = var.configuration_mode
    secret_mode       = var.secret_mode
    secret_names      = var.secret_names
    primary_target    = "aks"
  }

  kubernetes_artifacts = {
    namespace           = "app/k8s/namespace.yaml"
    configmap           = "app/k8s/configmap.yaml"
    secret_placeholder  = "app/k8s/secret-placeholder.yaml"
    deployment          = "app/k8s/deployment.yaml"
    service             = "app/k8s/service.yaml"
    ingress_placeholder = "app/k8s/ingress-placeholder.yaml"
    kustomization       = "app/k8s/kustomization.yaml"
  }

  planned_workloads = {
    aks         = local.aks_cluster_plan
    application = local.application_plan
    kubernetes  = local.kubernetes_artifacts
    jelastic_p4d = {
      enabled         = var.enable_jelastic_demo
      deployment_mode = var.enable_jelastic_demo ? "enabled" : "deferred"
      application     = var.application_name
      billing_model   = "external_or_service_specific"
      priority        = "secondary-future-target"
    }
  }
}
