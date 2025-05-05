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

# Create VPC network
resource "google_compute_network" "wordle_network" {
  name                    = "wordle-network"
  auto_create_subnetworks = false
}

# Create subnet
resource "google_compute_subnetwork" "wordle_subnet" {
  name          = "wordle-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.wordle_network.id
  region        = var.region
}

# Create firewall rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.wordle_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.wordle_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Create web server instances
resource "google_compute_instance" "web_servers" {
  count        = 2
  name         = "web-server-${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  tags = ["http-server", "ssh"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.wordle_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Create database server instance
resource "google_compute_instance" "db_server" {
  name         = "db-server"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  tags = ["ssh"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.wordle_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Output the IP addresses for Ansible
output "web_server_ips" {
  value = google_compute_instance.web_servers[*].network_interface[0].access_config[0].nat_ip
}

output "db_server_ip" {
  value = google_compute_instance.db_server.network_interface[0].access_config[0].nat_ip
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