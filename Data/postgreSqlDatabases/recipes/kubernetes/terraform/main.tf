terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

# ========================================
# Common Radius variables
# ========================================

variable "context" {
  description = "The Radius Recipe context variable. See https://docs.radapp.io/reference/context-schema/."
  type = any
}

locals {
  resource_name = var.context.resource.name
  namespace     = var.context.runtime.kubernetes.namespace
  
  # Extract resource properties
  resource_properties = try(var.context.resource.properties, {})

  # Extract last segment from environment path for labels
  environment_id    = try(local.resource_properties.environment, "")
  environment_parts = local.environment_id != "" ? split("/", local.environment_id) : []
  environment_label = length(local.environment_parts) > 0 ? local.environment_parts[length(local.environment_parts) - 1] : ""

  # Extract resource group name
  resource_group_name = split("/", var.context.resource.id)[4]

  # Application name
  application_name = var.context.application != null ? var.context.application.name : ""

  # Build unique name with length constraint (max 63 chars for Kubernetes)
  # Format: <app>-<resource>-<env>
  base_name = "${local.application_name}-${local.resource_name}-${local.environment_label}"
  
  # If too long, abbreviate application name
  uniqueName = length(local.base_name) > 63 ? (
    "${substr(local.application_name, 0, max(1, 63 - length(local.resource_name) - length(local.environment_label) - 2))}-${local.resource_name}-${local.environment_label}"
  ) : local.base_name

  # Build labels
  labels = {
    "radapp.io/resource"       = local.resource_name
    "radapp.io/application"    = local.application_name
    "radapp.io/environment"    = local.environment_label
    "radapp.io/resource-type"  = replace(var.context.resource.type, "/", "-")
    "radapp.io/resource-group" = local.resource_group_name
  }
}

# ========================================
# PostgreSQL variables
# ========================================

variable "memory" {
  description = "Memory limits for the PostgreSQL container"
  type = map(object({
    memoryRequest = string
  }))
  default = {
    S = {
      memoryRequest = "512Mi"
    },
    M = {
      memoryRequest = "1Gi"
    },
    L = {
      memoryRequest = "2Gi"
    }
  }
}

locals {
    port = 5432
    
    # Get the secret reference. Should be only a single connected resource.
    # connections = try(var.context.resource.connections, {})
    # connection = values(local.connections)[0]
    # secretName = connection.secretName

    secretName = var.context.resource.connections.creds.secretName
}

# ========================================
# Resources
# ========================================

resource "kubernetes_deployment" "postgresql" {
  metadata {
    name      = local.uniqueName
    namespace = local.namespace
    labels    = local.labels
  }

  spec {
    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          image = "postgres:16-alpine"
          name  = "postgres"
          resources {
            requests = {
              memory = var.memory[var.context.resource.properties.size].memoryRequest
              }
            }
          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = local.secretName
                key  = "username"
              }
            }
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = local.secretName
                key  = "password"
              }
            }
          }
          env {
            name  = "POSTGRES_DB"
            value = "postgres_db"
          }
          port {
            container_port = local.port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = local.uniqueName
    namespace = local.namespace
    labels    = local.labels
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = local.port
      target_port = local.port
    } 
  }
}

# ========================================
# Output Radius result 
# ========================================

output "result" {
  value = {
    resources = [
        "/planes/kubernetes/local/namespaces/${kubernetes_service.postgres.metadata[0].namespace}/providers/core/Service/${kubernetes_service.postgres.metadata[0].name}",
        "/planes/kubernetes/local/namespaces/${kubernetes_deployment.postgresql.metadata[0].namespace}/providers/apps/Deployment/${kubernetes_deployment.postgresql.metadata[0].name}"
    ]
    values = {
      host = "${kubernetes_service.postgres.metadata[0].name}.${kubernetes_service.postgres.metadata[0].namespace}.svc.cluster.local"
      port = local.port
      database = "postgres_db"
    }
  }
}
