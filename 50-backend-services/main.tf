data "terraform_remote_state" "k8s_base" {
  backend = "local"
  config = {
    path = "../30-k8s-base/terraform.tfstate"
  }
}

data "terraform_remote_state" "data_services" {
  backend = "local"
  config = {
    path = "../40-data-services/terraform.tfstate"
  }
}

locals {
  namespace      = data.terraform_remote_state.k8s_base.outputs.namespace
  image_registry = var.image_registry
  image_tag      = var.image_tag
}

resource "kubernetes_config_map_v1" "order_service" {
  metadata {
    name      = "order-service-configs"
    namespace = local.namespace
  }

  data = {
    ORDER_QUEUE_PORT     = "5672"
    ORDER_QUEUE_HOSTNAME = data.terraform_remote_state.data_services.outputs.rabbitmq_service_name
    ORDER_QUEUE_NAME     = "orders"
    FASTIFY_ADDRESS      = "0.0.0.0"
  }
}

resource "kubernetes_secret_v1" "order_service" {
  metadata {
    name      = "order-service-secrets"
    namespace = local.namespace
  }

  data = {
    ORDER_QUEUE_USERNAME = var.rabbitmq_username
    ORDER_QUEUE_PASSWORD = var.rabbitmq_password
  }

  type = "Opaque"
}

resource "kubernetes_deployment_v1" "order_service" {
  metadata {
    name      = "order-service"
    namespace = local.namespace
    labels = {
      app = "order-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "order-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "order-service"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        init_container {
          name  = "wait-for-rabbitmq"
          image = "busybox:1.37.0"
          command = [
            "sh",
            "-c",
            "until nc -zv rabbitmq 5672; do echo waiting for rabbitmq; sleep 2; done;"
          ]

          resources {
            requests = {
              cpu    = "1m"
              memory = "50Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }

        container {
          name  = "order-service"
          image = "${local.image_registry}/order-service:${local.image_tag}"

          port {
            container_port = 3000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.order_service.metadata[0].name
            }
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.order_service.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "1m"
              memory = "50Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            failure_threshold     = 5
            initial_delay_seconds = 20
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            failure_threshold     = 5
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "order_service" {
  metadata {
    name      = "order-service"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "order-service"
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "makeline_service" {
  metadata {
    name      = "makeline-service"
    namespace = local.namespace
    labels = {
      app = "makeline-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "makeline-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "makeline-service"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "makeline-service"
          image = "${local.image_registry}/makeline-service:${local.image_tag}"

          port {
            container_port = 3001
          }

          env {
            name  = "ORDER_QUEUE_URI"
            value = "amqp://rabbitmq:5672"
          }
          env {
            name  = "ORDER_QUEUE_USERNAME"
            value = var.rabbitmq_username
          }
          env {
            name  = "ORDER_QUEUE_PASSWORD"
            value = var.rabbitmq_password
          }
          env {
            name  = "ORDER_QUEUE_NAME"
            value = "orders"
          }
          env {
            name  = "ORDER_DB_URI"
            value = "mongodb://mongodb:27017"
          }
          env {
            name  = "ORDER_DB_NAME"
            value = "orderdb"
          }
          env {
            name  = "ORDER_DB_COLLECTION_NAME"
            value = "orders"
          }

          resources {
            requests = {
              cpu    = "1m"
              memory = "6Mi"
            }
            limits = {
              cpu    = "5m"
              memory = "20Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            failure_threshold = 10
            period_seconds    = 5
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3001
            }
            failure_threshold     = 5
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "makeline_service" {
  metadata {
    name      = "makeline-service"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "makeline-service"
    }

    port {
      name        = "http"
      port        = 3001
      target_port = 3001
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "product_service" {
  metadata {
    name      = "product-service"
    namespace = local.namespace
    labels = {
      app = "product-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "product-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "product-service"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "product-service"
          image = "${local.image_registry}/product-service:${local.image_tag}"

          port {
            container_port = 3002
          }

          env {
            name  = "AI_SERVICE_URL"
            value = "http://ai-service:5001/"
          }

          resources {
            requests = {
              cpu    = "1m"
              memory = "1Mi"
            }
            limits = {
              cpu    = "2m"
              memory = "20Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3002
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3002
            }
            failure_threshold     = 5
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "product_service" {
  metadata {
    name      = "product-service"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "product-service"
    }

    port {
      name        = "http"
      port        = 3002
      target_port = 3002
    }

    type = "ClusterIP"
  }
}
