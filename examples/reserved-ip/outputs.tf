output "instance_id" {
  description = "OCID of the instance"
  value       = module.instance.id
}

output "reserved_public_ip" {
  description = "The reserved public IP address"
  value       = module.instance.reserved_public_ip_address
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = module.instance.public_ip
}

output "secondary_reserved_public_ips" {
  description = "Map of secondary network interface name to its reserved public IP resource"
  value       = module.instance.secondary_reserved_public_ips
}
