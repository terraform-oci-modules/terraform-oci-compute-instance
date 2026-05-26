output "instance_id" {
  description = "The OCID of the instance"
  value       = module.instance.id
}

output "private_ip" {
  description = "The private IP address of the instance"
  value       = module.instance.private_ip
}

output "public_ip" {
  description = "The reserved public IP address"
  value       = module.instance.public_ip
}

output "boot_volume_id" {
  description = "The OCID of the boot volume"
  value       = module.instance.boot_volume_id
}

output "block_volumes" {
  description = "Map of block volume attributes"
  value       = module.instance.block_volumes
}

output "nsg_id" {
  description = "The OCID of the created NSG"
  value       = module.instance.nsg_id
}
