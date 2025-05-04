terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Create Artifact Registry repository
resource "google_artifact_registry_repository" "wordle" {
  location      = var.region
  repository_id = "wordle"
  description   = "Docker repository for Wordle clone"
  format        = "DOCKER"
}

# Create Cloud Run service
resource "google_cloud_run_service" "wordle" {
  name     = "wordle"
  location = var.region

  template {
    spec {
      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/wordle/wordle:latest"
        ports {
          container_port = 8080
        }
        env {
          name  = "NODE_ENV"
          value = "production"
        }
        startup_probe {
          initial_delay_seconds = 0
          timeout_seconds      = 240
          period_seconds       = 240
          failure_threshold    = 1
          tcp_socket {
            port = 8080
          }
        }
        liveness_probe {
          http_get {
            path = "/"
            port = 8080
          }
          initial_delay_seconds = 0
          timeout_seconds      = 240
          period_seconds       = 240
          failure_threshold    = 1
        }
      }
      timeout_seconds = 300
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Make the service publicly accessible
resource "google_cloud_run_service_iam_member" "public" {
  service  = google_cloud_run_service.wordle.name
  location = google_cloud_run_service.wordle.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the service URL
output "service_url" {
  value = google_cloud_run_service.wordle.status[0].url
} 