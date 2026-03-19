provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable compute engine API
resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
}

# Default network (simplest for challenge)
resource "google_compute_network" "vpc_network" {
  name                    = "challange-3-network"
  auto_create_subnetworks = true

  depends_on = [
    google_project_service.compute_api
  ]
}

# Firewall rule: allow HTTP + SSH
resource "google_compute_firewall" "allow_http_ssh" {
  name    = "allow-http-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]

  depends_on = [
    google_project_service.compute_api
  ]
}

# VM Instance
resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["http-server", "ssh"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = file("startup.sh")

  depends_on = [
    google_project_service.compute_api
  ]
}