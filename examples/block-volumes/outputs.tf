output "instance_id" {
  description = "The OCID of the instance"
  value       = module.instance.id
}

output "block_volumes" {
  description = "Map of block volume attributes (id, availability_domain, size_in_gbs)"
  value       = module.instance.block_volumes
}

output "block_volume_attachments" {
  description = "Block volume attachment details (includes iSCSI connection info)"
  value       = module.instance.block_volume_attachments
}
