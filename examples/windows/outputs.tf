output "instance_id" {
  description = "The OCID of the Windows instance"
  value       = module.instance.id
}

output "public_ip" {
  description = "The public IP address of the Windows instance (for RDP access)"
  value       = module.instance.public_ip
}

output "instance_credentials" {
  description = "Initial Windows credentials (username + password). Treat as sensitive"
  sensitive   = true
  value       = module.instance.instance_credentials
}
