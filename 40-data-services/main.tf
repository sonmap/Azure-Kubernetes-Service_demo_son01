data "terraform_remote_state" "k8s_base" {
  backend = "local"

  config = {
    path = "../30-k8s-base/terraform.tfstate"
  }
}

locals {
  namespace = data.terraform_remote_state.k8s_base.outputs.namespace
}

resource "kubernetes_stateful_set_v1" "mongodb" {
  # MongoDB can take time to become ready on small lab nodes. Terraform still creates the
  # StatefulSet, and Kubernetes probes below control the real health status.
  wait_for_rollout = false

  metadata {
    name      = "mongodb"
    namespace = local.namespace

    labels = {
      app = "mongodb"
    }
  }

  spec {
    service_name = "mongodb"
    replicas     = 1

    selector {
      match_labels = {
        app = "mongodb"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongodb"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "mongodb"
          image = "mcr.microsoft.com/mirror/docker/library/mongo:4.2"

          port {
            container_port = 27017
            name           = "mongodb"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "1024Mi"
            }
          }

          startup_probe {
            tcp_socket {
              port = 27017
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 10
            failure_threshold     = 30
          }

          readiness_probe {
            tcp_socket {
              port = 27017
            }

            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 10
            failure_threshold     = 10
          }

          liveness_probe {
            tcp_socket {
              port = 27017
            }

            initial_delay_seconds = 120
            period_seconds        = 10
            timeout_seconds       = 10
            failure_threshold     = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "mongodb"
    }

    port {
      name        = "mongodb"
      port        = 27017
      target_port = 27017
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_config_map_v1" "rabbitmq_plugins" {
  metadata {
    name      = "rabbitmq-enabled-plugins"
    namespace = local.namespace
  }

  data = {
    rabbitmq_enabled_plugins = "[rabbitmq_management,rabbitmq_prometheus,rabbitmq_amqp1_0]."
  }
}

resource "kubernetes_secret_v1" "rabbitmq" {
  metadata {
    name      = "rabbitmq-secrets"
    namespace = local.namespace
  }

  data = {
    RABBITMQ_DEFAULT_USER = var.rabbitmq_username
    RABBITMQ_DEFAULT_PASS = var.rabbitmq_password
  }

  type = "Opaque"
}

resource "kubernetes_stateful_set_v1" "rabbitmq" {
  wait_for_rollout = false

  metadata {
    name      = "rabbitmq"
    namespace = local.namespace

    labels = {
      app = "rabbitmq"
    }
  }

  spec {
    service_name = "rabbitmq"
    replicas     = 1

    selector {
      match_labels = {
        app = "rabbitmq"
      }
    }

    template {
      metadata {
        labels = {
          app = "rabbitmq"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        container {
          name  = "rabbitmq"
          image = "mcr.microsoft.com/azurelinux/base/rabbitmq-server:3.13"

          port {
            container_port = 5672
            name           = "rabbitmq-amqp"
          }

          port {
            container_port = 15672
            name           = "rabbitmq-http"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.rabbitmq.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "10m"
              memory = "128Mi"
            }

            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          startup_probe {
            tcp_socket {
              port = 5672
            }

            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 30
          }

          readiness_probe {
            tcp_socket {
              port = 5672
            }

            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          liveness_probe {
            tcp_socket {
              port = 5672
            }

            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          volume_mount {
            name       = "rabbitmq-enabled-plugins"
            mount_path = "/etc/rabbitmq/enabled_plugins"
            sub_path   = "enabled_plugins"
          }
        }

        volume {
          name = "rabbitmq-enabled-plugins"

          config_map {
            name = kubernetes_config_map_v1.rabbitmq_plugins.metadata[0].name

            items {
              key  = "rabbitmq_enabled_plugins"
              path = "enabled_plugins"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "rabbitmq" {
  metadata {
    name      = "rabbitmq"
    namespace = local.namespace
  }

  spec {
    selector = {
      app = "rabbitmq"
    }

    port {
      name        = "rabbitmq-amqp"
      port        = 5672
      target_port = 5672
    }

    port {
      name        = "rabbitmq-http"
      port        = 15672
      target_port = 15672
    }

    type = "ClusterIP"
  }
}
