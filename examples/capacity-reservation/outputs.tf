output "capacity_reservation_id" {
  description = "The OCID of the capacity reservation"
  value       = oci_core_compute_capacity_reservation.this.id
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
