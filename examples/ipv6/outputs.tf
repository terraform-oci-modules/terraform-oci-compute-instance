output "vcn_ipv6_cidr_block" {
  description = "The /56 IPv6 CIDR block assigned to the VCN by OCI"
  value       = try(module.vcn.vcn_ipv6_cidr_blocks[0], null)
}

output "instance_id" {
  description = "The OCID of the instance"
  value       = module.instance.id
}

output "private_ip" {
  description = "The private IPv4 address of the instance"
  value       = module.instance.private_ip
}

output "public_ip" {
  description = "The public IPv4 address of the instance"
  value       = module.instance.public_ip
}

output "availability_domain" {
  description = "The availability domain where the instance was placed"
  value       = module.instance.availability_domain
}
