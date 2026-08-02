output "vcn_id" {
  description = "The OCID of the VCN"
  value       = module.vcn.vcn_id
}

output "private_subnet_ids" {
  description = "The OCIDs of the private subnets"
  value       = module.vcn.private_subnets
}

output "instance_id" {
  description = "The OCID of the instance"
  value       = module.instance.id
}

output "primary_private_ip" {
  description = "The private IP address of the primary VNIC"
  value       = module.instance.private_ip
}

output "secondary_network_interfaces" {
  description = "Resolved attributes of the secondary VNICs: {vnic_id, nic_index, private_ip, public_ip, mac_address}"
  value       = module.instance.secondary_network_interfaces
}
