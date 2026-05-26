output "vcn_id" {
  description = "The OCID of the VCN"
  value       = module.vcn.vcn_id
}

output "private_subnet_id" {
  description = "The OCID of the private subnet the instance was placed in"
  value       = module.vcn.private_subnets[0]
}

output "instance_id" {
  description = "The OCID of the instance"
  value       = module.instance.id
}

output "private_ip" {
  description = "The private IP address of the instance"
  value       = module.instance.private_ip
}

output "availability_domain" {
  description = "The availability domain where the instance was placed"
  value       = module.instance.availability_domain
}
