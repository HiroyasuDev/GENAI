# ==============================================================================
# OpenCode AI Lab — Terraform Configuration
# ==============================================================================
# Spins up a fully self-contained AI coding lab on GCP:
#   - GCP Compute Engine VM (e2-standard-4)
#   - MiniMax-M2.7 LLM via llama.cpp
#   - OpenCode agentic TUI
#   - ttyd web terminal (browser-accessible)
#   - Firewall rules for public access
#
# Usage:
#   1. cp terraform.tfvars.example terraform.tfvars
#   2. Edit terraform.tfvars with your GCP project ID
#   3. terraform init
#   4. terraform apply
#   5. Wait ~5-8 minutes for the startup script to finish
#   6. Open the output URL in any browser
#
# Teardown:
#   terraform destroy
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Provider
# ------------------------------------------------------------------------------
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ------------------------------------------------------------------------------
# Network — use default VPC
# ------------------------------------------------------------------------------
data "google_compute_network" "default" {
  name = "default"
}

# ------------------------------------------------------------------------------
# Firewall — allow ttyd web terminal (port 7681)
# ------------------------------------------------------------------------------
resource "google_compute_firewall" "allow_ttyd" {
  name    = "${var.instance_name}-allow-ttyd"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["7681"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = [var.instance_name]

  description = "Allow public access to ttyd web terminal for OpenCode AI Lab"
}

# ------------------------------------------------------------------------------
# Firewall — allow SSH (port 22)
# ------------------------------------------------------------------------------
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.instance_name}-allow-ssh"
  network = data.google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = [var.instance_name]

  description = "Allow SSH access for OpenCode AI Lab VM"
}

# ------------------------------------------------------------------------------
# Static External IP (optional — predictable URL)
# ------------------------------------------------------------------------------
resource "google_compute_address" "lab_ip" {
  name         = "${var.instance_name}-ip"
  address_type = "EXTERNAL"
  region       = var.region
}

# ------------------------------------------------------------------------------
# Compute Engine VM
# ------------------------------------------------------------------------------
resource "google_compute_instance" "opencode_lab" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = [var.instance_name]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = var.disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    network = data.google_compute_network.default.name
    access_config {
      nat_ip = google_compute_address.lab_ip.address
    }
  }

  # The startup script that builds and launches the entire stack
  metadata_startup_script = file("${path.module}/startup.sh")

  metadata = {
    enable-oslogin = "FALSE"
  }

  # Allow the VM to pull from GCS / HuggingFace
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  # Ensure firewall rules are created before the VM
  depends_on = [
    google_compute_firewall.allow_ttyd,
    google_compute_firewall.allow_ssh,
  ]
}
