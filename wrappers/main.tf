module "wrapper" {
  source = "../"

  for_each = var.items

  are_all_plugins_disabled                 = try(each.value.are_all_plugins_disabled, var.defaults.are_all_plugins_disabled, false)
  assign_ipv6ip                            = try(each.value.assign_ipv6ip, var.defaults.assign_ipv6ip, false)
  assign_public_ip                         = try(each.value.assign_public_ip, var.defaults.assign_public_ip, false)
  availability_domain                      = try(each.value.availability_domain, var.defaults.availability_domain, 1)
  block_volumes                            = try(each.value.block_volumes, var.defaults.block_volumes, {})
  boot_volume_backup_policy                = try(each.value.boot_volume_backup_policy, var.defaults.boot_volume_backup_policy, "disabled")
  boot_volume_encryption_key_id            = try(each.value.boot_volume_encryption_key_id, var.defaults.boot_volume_encryption_key_id, null)
  boot_volume_size_in_gbs                  = try(each.value.boot_volume_size_in_gbs, var.defaults.boot_volume_size_in_gbs, null)
  boot_volume_vpus_per_gb                  = try(each.value.boot_volume_vpus_per_gb, var.defaults.boot_volume_vpus_per_gb, null)
  capacity_reservation_id                  = try(each.value.capacity_reservation_id, var.defaults.capacity_reservation_id, null)
  cloud_agent_plugins                      = try(each.value.cloud_agent_plugins, var.defaults.cloud_agent_plugins, {})
  compartment_id                           = try(each.value.compartment_id, var.defaults.compartment_id)
  create                                   = try(each.value.create, var.defaults.create, true)
  create_nsg                               = try(each.value.create_nsg, var.defaults.create_nsg, false)
  create_reserved_public_ip                = try(each.value.create_reserved_public_ip, var.defaults.create_reserved_public_ip, false)
  dedicated_vm_host_id                     = try(each.value.dedicated_vm_host_id, var.defaults.dedicated_vm_host_id, null)
  defined_tags                             = try(each.value.defined_tags, var.defaults.defined_tags, {})
  extended_metadata                        = try(each.value.extended_metadata, var.defaults.extended_metadata, {})
  fault_domain                             = try(each.value.fault_domain, var.defaults.fault_domain, null)
  hostname_label                           = try(each.value.hostname_label, var.defaults.hostname_label, null)
  ignore_image_changes                     = try(each.value.ignore_image_changes, var.defaults.ignore_image_changes, false)
  instance_defined_tags                    = try(each.value.instance_defined_tags, var.defaults.instance_defined_tags, {})
  instance_initiated_shutdown_behavior     = try(each.value.instance_initiated_shutdown_behavior, var.defaults.instance_initiated_shutdown_behavior, null)
  instance_state                           = try(each.value.instance_state, var.defaults.instance_state, "RUNNING")
  instance_tags                            = try(each.value.instance_tags, var.defaults.instance_tags, {})
  ipv6address_ipv6subnet_cidr_pair_details = try(each.value.ipv6address_ipv6subnet_cidr_pair_details, var.defaults.ipv6address_ipv6subnet_cidr_pair_details, [])
  ipxe_script                              = try(each.value.ipxe_script, var.defaults.ipxe_script, null)
  is_management_disabled                   = try(each.value.is_management_disabled, var.defaults.is_management_disabled, false)
  is_monitoring_disabled                   = try(each.value.is_monitoring_disabled, var.defaults.is_monitoring_disabled, false)
  is_pv_encryption_in_transit_enabled      = try(each.value.is_pv_encryption_in_transit_enabled, var.defaults.is_pv_encryption_in_transit_enabled, true)
  is_windows_instance                      = try(each.value.is_windows_instance, var.defaults.is_windows_instance, false)
  metadata_options                         = try(each.value.metadata_options, var.defaults.metadata_options, {})
  name                                     = try(each.value.name, var.defaults.name, "")
  nsg_egress_rules = try(each.value.nsg_egress_rules, var.defaults.nsg_egress_rules, {
    allow_all_ipv4 = {
      protocol         = "all"
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      description      = "Allow all outbound IPv4 traffic"
    }
    allow_all_ipv6 = {
      protocol         = "all"
      destination      = "::/0"
      destination_type = "CIDR_BLOCK"
      description      = "Allow all outbound IPv6 traffic"
    }
  })
  nsg_ids                     = try(each.value.nsg_ids, var.defaults.nsg_ids, [])
  nsg_ingress_rules           = try(each.value.nsg_ingress_rules, var.defaults.nsg_ingress_rules, {})
  nsg_name                    = try(each.value.nsg_name, var.defaults.nsg_name, null)
  nsg_tags                    = try(each.value.nsg_tags, var.defaults.nsg_tags, {})
  nsg_vcn_id                  = try(each.value.nsg_vcn_id, var.defaults.nsg_vcn_id, null)
  preemptible_instance_config = try(each.value.preemptible_instance_config, var.defaults.preemptible_instance_config, null)
  preserve_boot_volume        = try(each.value.preserve_boot_volume, var.defaults.preserve_boot_volume, false)
  private_ip                  = try(each.value.private_ip, var.defaults.private_ip, null)
  reserved_public_ip_tags     = try(each.value.reserved_public_ip_tags, var.defaults.reserved_public_ip_tags, {})
  secondary_network_interface = try(each.value.secondary_network_interface, var.defaults.secondary_network_interface, {})
  shape                       = try(each.value.shape, var.defaults.shape, "VM.Standard.E4.Flex")
  shape_config                = try(each.value.shape_config, var.defaults.shape_config, {})
  source_dest_check           = try(each.value.source_dest_check, var.defaults.source_dest_check, true)
  source_id                   = try(each.value.source_id, var.defaults.source_id, null)
  source_type                 = try(each.value.source_type, var.defaults.source_type, "image")
  ssh_authorized_keys         = try(each.value.ssh_authorized_keys, var.defaults.ssh_authorized_keys, null)
  subnet_id                   = try(each.value.subnet_id, var.defaults.subnet_id, null)
  tags                        = try(each.value.tags, var.defaults.tags, {})
  timeouts                    = try(each.value.timeouts, var.defaults.timeouts, null)
  user_data                   = try(each.value.user_data, var.defaults.user_data, null)
}
