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

resource "kubernetes_deployment_v1" "store_front" {
  metadata {
    name      = "store-front"
    namespace = local.namespace
    labels = {
      app = "store-front"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "store-front"
      }
    }

    template {
      metadata {
        labels = {
          app = "store-front"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "store-front"
          image = "${local.image_registry}/store-front:${local.image_tag}"

          port {
            container_port = 8080
            name           = "store-front"
          }

          resources {
            requests = {
              cpu    = "1m"
              memory = "200Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "512Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            failure_threshold     = 3
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 3
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
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

resource "kubernetes_service_v1" "store_front" {
  wait_for_load_balancer = true

  metadata {
    name      = "store-front"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "store-front"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment_v1" "store_admin" {
  metadata {
    name      = "store-admin"
    namespace = local.namespace
    labels = {
      app = "store-admin"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "store-admin"
      }
    }

    template {
      metadata {
        labels = {
          app = "store-admin"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "store-admin"
          image = "${local.image_registry}/store-admin:${local.image_tag}"

          port {
            container_port = 8081
            name           = "store-admin"
          }

          resources {
            requests = {
              cpu    = "1m"
              memory = "200Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "512Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 8081
            }
            failure_threshold     = 3
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8081
            }
            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8081
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

resource "kubernetes_service_v1" "store_admin" {
  wait_for_load_balancer = true

  metadata {
    name      = "store-admin"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "store-admin"
    }

    port {
      port        = 80
      target_port = 8081
    }

    type = "LoadBalancer"
  }
}
