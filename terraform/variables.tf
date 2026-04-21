# ==============================================================================
# Variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Name of the VM instance"
  type        = string
  default     = "opencode-lab-vm"
}

variable "machine_type" {
  description = "GCP machine type (e2-standard-4 = 4 vCPU, 16 GB RAM)"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "allowed_source_ranges" {
  description = "CIDR ranges allowed to access the web terminal. Default: open to all."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
