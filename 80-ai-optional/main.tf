data "terraform_remote_state" "k8s_base" {
  backend = "local"
  config = {
    path = "../30-k8s-base/terraform.tfstate"
  }
}

locals {
  namespace      = data.terraform_remote_state.k8s_base.outputs.namespace
  image_registry = var.image_registry
  image_tag      = var.image_tag
}

resource "kubernetes_secret_v1" "ai_service" {
  count = var.enable_ai_service ? 1 : 0

  metadata {
    name      = "ai-service-secrets"
    namespace = local.namespace
  }

  data = {
    OPENAI_API_KEY = var.openai_api_key
  }

  type = "Opaque"
}

resource "kubernetes_config_map_v1" "ai_service" {
  count = var.enable_ai_service ? 1 : 0

  metadata {
    name      = "ai-service-configs"
    namespace = local.namespace
  }

  data = {
    USE_AZURE_OPENAI             = var.use_azure_openai
    AZURE_OPENAI_DEPLOYMENT_NAME = var.azure_openai_deployment_name
    AZURE_OPENAI_ENDPOINT        = var.azure_openai_endpoint
    OPENAI_ORG_ID                = var.openai_org_id
  }
}

resource "kubernetes_deployment_v1" "ai_service" {
  count = var.enable_ai_service ? 1 : 0

  metadata {
    name      = "ai-service"
    namespace = local.namespace
    labels = {
      app = "ai-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "ai-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "ai-service"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "ai-service"
          image = "${local.image_registry}/ai-service:${local.image_tag}"

          port {
            container_port = 5001
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.ai_service[0].metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.ai_service[0].metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "1m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 5001
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            failure_threshold     = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 5001
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            failure_threshold     = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "ai_service" {
  count = var.enable_ai_service ? 1 : 0

  metadata {
    name      = "ai-service"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "ai-service"
    }

    port {
      name        = "http"
      port        = 5001
      target_port = 5001
    }

    type = "ClusterIP"
  }
}
