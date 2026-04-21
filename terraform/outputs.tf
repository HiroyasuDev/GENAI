# ==============================================================================
# Outputs
# ==============================================================================

output "lab_url" {
  description = "Public URL for the OpenCode AI Lab web terminal"
  value       = "http://${google_compute_address.lab_ip.address}:7681"
}

output "vm_external_ip" {
  description = "External IP address of the lab VM"
  value       = google_compute_address.lab_ip.address
}

output "ssh_command" {
  description = "SSH command to access the VM"
  value       = "gcloud compute ssh ${var.instance_name} --zone=${var.zone} --project=${var.project_id}"
}

output "teardown_command" {
  description = "Command to destroy all resources"
  value       = "terraform destroy -auto-approve"
}

output "github_pages_update" {
  description = "Command to update the GitHub Pages landing page with the new IP"
  value       = "Update docs/index.html: replace the href in the Launch button with http://${google_compute_address.lab_ip.address}:7681"
}
