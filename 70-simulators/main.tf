data "terraform_remote_state" "k8s_base" {
  backend = "local"
  config = {
    path = "../30-k8s-base/terraform.tfstate"
  }
}

data "terraform_remote_state" "backend_services" {
  backend = "local"
  config = {
    path = "../50-backend-services/terraform.tfstate"
  }
}

locals {
  namespace      = data.terraform_remote_state.k8s_base.outputs.namespace
  image_registry = var.image_registry
  image_tag      = var.image_tag
}

resource "kubernetes_deployment_v1" "virtual_customer" {
  metadata {
    name      = "virtual-customer"
    namespace = local.namespace
    labels = {
      app = "virtual-customer"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "virtual-customer"
      }
    }

    template {
      metadata {
        labels = {
          app = "virtual-customer"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "virtual-customer"
          image = "${local.image_registry}/virtual-customer:${local.image_tag}"

          env {
            name  = "ORDER_SERVICE_URL"
            value = "http://order-service:3000/"
          }

          env {
            name  = "ORDERS_PER_HOUR"
            value = var.orders_per_hour
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
            exec {
              command = ["cat", "/proc/1/status"]
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            exec {
              command = ["cat", "/proc/1/status"]
            }
            failure_threshold     = 5
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "virtual_worker" {
  metadata {
    name      = "virtual-worker"
    namespace = local.namespace
    labels = {
      app = "virtual-worker"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "virtual-worker"
      }
    }

    template {
      metadata {
        labels = {
          app = "virtual-worker"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "virtual-worker"
          image = "${local.image_registry}/virtual-worker:${local.image_tag}"

          env {
            name  = "MAKELINE_SERVICE_URL"
            value = "http://makeline-service:3001"
          }

          env {
            name  = "ORDERS_PER_HOUR"
            value = var.orders_per_hour
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
            exec {
              command = ["cat", "/proc/1/status"]
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            exec {
              command = ["cat", "/proc/1/status"]
            }
            failure_threshold     = 5
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }
}
