output "standard_flex_id" {
  description = "OCID of the standard flex instance"
  value       = module.standard_flex.id
}

output "burstable_flex_id" {
  description = "OCID of the burstable flex instance"
  value       = module.burstable_flex.id
}

output "micro_flex_id" {
  description = "OCID of the micro burstable flex instance"
  value       = module.micro_flex.id
}
