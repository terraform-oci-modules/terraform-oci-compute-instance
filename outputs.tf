################################################################################
# Instance
################################################################################

output "id" {
  description = "The OCID of the instance"
  value       = try(local.instance.id, null)
}

output "availability_domain" {
  description = "The availability domain name where the instance was placed"
  value       = try(local.instance.availability_domain, null)
}

output "state" {
  description = "The current state of the instance (RUNNING, STOPPED, TERMINATED, etc.)"
  value       = try(local.instance.state, null)
}

output "shape" {
  description = "The shape of the instance"
  value       = try(local.instance.shape, null)
}

output "private_ip" {
  description = "The private IP address of the primary VNIC"
  value       = try(local.instance.private_ip, null)
}

output "public_ip" {
  description = "The public IP address of the instance (ephemeral or reserved). Null when no public IP is assigned"
  value = try(
    oci_core_public_ip.this[0].ip_address,
    local.instance.public_ip,
    null,
  )
}

output "hostname_label" {
  description = "The hostname label of the instance in the subnet DNS zone"
  # local.instance.hostname_label is a deprecated top-level shorthand for
  # this same value; read it from create_vnic_details instead, which is not
  # deprecated.
  value = try(local.instance.create_vnic_details[0].hostname_label, null)
}

output "primary_vnic_id" {
  description = "The OCID of the primary VNIC attachment"
  value       = try(data.oci_core_vnic_attachments.this[0].vnic_attachments[0].vnic_id, null)
}

output "boot_volume_id" {
  description = "The OCID of the boot volume"
  value       = try(local.instance.boot_volume_id, null)
}

output "image_id" {
  description = "The OCID of the source image used to launch the instance"
  value       = try(local.instance.source_details[0].source_id, null)
}

output "instance_all_attributes" {
  # Manually enumerated (not auto-updating) to exclude 3 deprecated top-level
  # attributes: hostname_label (see the create_vnic_details.hostname_label
  # field below, and the dedicated hostname_label output above), image (see
  # source_details.source_id below, and the dedicated image_id output), and
  # subnet_id (see create_vnic_details.subnet_id below).
  description = "Attributes of the created instance, excluding 3 deprecated top-level fields (hostname_label, image, subnet_id) whose non-deprecated equivalents are included under create_vnic_details/source_details"
  sensitive   = true
  # try(..., null) rather than a `local.instance == null ? null : {...}`
  # guard: the equality comparison would itself read local.instance wholesale
  # (to compare against null), which re-triggers the deprecation warning this
  # output exists to avoid, even though the comparison never dot-references
  # any deprecated field directly.
  value = try({
    async                                   = local.instance.async
    availability_domain                     = local.instance.availability_domain
    boot_volume_id                          = local.instance.boot_volume_id
    capacity_reservation_id                 = local.instance.capacity_reservation_id
    cluster_placement_group_id              = local.instance.cluster_placement_group_id
    compartment_id                          = local.instance.compartment_id
    compute_cluster_id                      = local.instance.compute_cluster_id
    dedicated_vm_host_id                    = local.instance.dedicated_vm_host_id
    defined_tags                            = local.instance.defined_tags
    display_name                            = local.instance.display_name
    extended_metadata                       = local.instance.extended_metadata
    fault_domain                            = local.instance.fault_domain
    freeform_tags                           = local.instance.freeform_tags
    id                                      = local.instance.id
    instance_configuration_id               = local.instance.instance_configuration_id
    ipxe_script                             = local.instance.ipxe_script
    is_ai_enterprise_enabled                = local.instance.is_ai_enterprise_enabled
    is_cross_numa_node                      = local.instance.is_cross_numa_node
    is_pv_encryption_in_transit_enabled     = local.instance.is_pv_encryption_in_transit_enabled
    launch_mode                             = local.instance.launch_mode
    metadata                                = local.instance.metadata
    preserve_boot_volume                    = local.instance.preserve_boot_volume
    preserve_data_volumes_created_at_launch = local.instance.preserve_data_volumes_created_at_launch
    private_ip                              = local.instance.private_ip
    public_ip                               = local.instance.public_ip
    region                                  = local.instance.region
    security_attributes                     = local.instance.security_attributes
    security_attributes_state               = local.instance.security_attributes_state
    shape                                   = local.instance.shape
    state                                   = local.instance.state
    system_tags                             = local.instance.system_tags
    time_created                            = local.instance.time_created
    time_maintenance_reboot_due             = local.instance.time_maintenance_reboot_due
    update_operation_constraint             = local.instance.update_operation_constraint

    agent_config = try({
      is_monitoring_disabled   = one(local.instance.agent_config).is_monitoring_disabled
      is_management_disabled   = one(local.instance.agent_config).is_management_disabled
      are_all_plugins_disabled = one(local.instance.agent_config).are_all_plugins_disabled
      plugins_config = [
        for p in one(local.instance.agent_config).plugins_config : {
          name          = p.name
          desired_state = p.desired_state
        }
      ]
    }, null)

    availability_config = try({
      is_live_migration_preferred = one(local.instance.availability_config).is_live_migration_preferred
      recovery_action             = one(local.instance.availability_config).recovery_action
    }, null)

    create_vnic_details = try({
      assign_ipv6ip             = one(local.instance.create_vnic_details).assign_ipv6ip
      assign_private_dns_record = one(local.instance.create_vnic_details).assign_private_dns_record
      assign_public_ip          = one(local.instance.create_vnic_details).assign_public_ip
      defined_tags              = one(local.instance.create_vnic_details).defined_tags
      display_name              = one(local.instance.create_vnic_details).display_name
      freeform_tags             = one(local.instance.create_vnic_details).freeform_tags
      hostname_label            = one(local.instance.create_vnic_details).hostname_label
      nsg_ids                   = one(local.instance.create_vnic_details).nsg_ids
      private_ip                = one(local.instance.create_vnic_details).private_ip
      private_ip_id             = one(local.instance.create_vnic_details).private_ip_id
      security_attributes       = one(local.instance.create_vnic_details).security_attributes
      skip_source_dest_check    = one(local.instance.create_vnic_details).skip_source_dest_check
      subnet_cidr               = one(local.instance.create_vnic_details).subnet_cidr
      subnet_id                 = one(local.instance.create_vnic_details).subnet_id
      vlan_id                   = one(local.instance.create_vnic_details).vlan_id
      ipv6address_ipv6subnet_cidr_pair_details = [
        for p in one(local.instance.create_vnic_details).ipv6address_ipv6subnet_cidr_pair_details : {
          ipv6address     = p.ipv6address
          ipv6id          = p.ipv6id
          ipv6subnet_cidr = p.ipv6subnet_cidr
        }
      ]
    }, null)

    instance_options = try({
      are_legacy_imds_endpoints_disabled = one(local.instance.instance_options).are_legacy_imds_endpoints_disabled
    }, null)

    launch_options = try({
      boot_volume_type                    = one(local.instance.launch_options).boot_volume_type
      firmware                            = one(local.instance.launch_options).firmware
      is_consistent_volume_naming_enabled = one(local.instance.launch_options).is_consistent_volume_naming_enabled
      is_pv_encryption_in_transit_enabled = one(local.instance.launch_options).is_pv_encryption_in_transit_enabled
      network_type                        = one(local.instance.launch_options).network_type
      remote_data_volume_type             = one(local.instance.launch_options).remote_data_volume_type
    }, null)

    launch_volume_attachments = [
      for a in local.instance.launch_volume_attachments : {
        device                              = a.device
        display_name                        = a.display_name
        encryption_in_transit_type          = a.encryption_in_transit_type
        is_agent_auto_iscsi_login_enabled   = a.is_agent_auto_iscsi_login_enabled
        is_pv_encryption_in_transit_enabled = a.is_pv_encryption_in_transit_enabled
        is_read_only                        = a.is_read_only
        is_shareable                        = a.is_shareable
        type                                = a.type
        use_chap                            = a.use_chap
        volume_id                           = a.volume_id
        launch_create_volume_details = [
          for c in a.launch_create_volume_details : {
            compartment_id       = c.compartment_id
            display_name         = c.display_name
            kms_key_id           = c.kms_key_id
            size_in_gbs          = c.size_in_gbs
            volume_creation_type = c.volume_creation_type
            vpus_per_gb          = c.vpus_per_gb
          }
        ]
      }
    ]

    licensing_configs = [
      for l in local.instance.licensing_configs : {
        license_type = l.license_type
        os_version   = l.os_version
        type         = l.type
      }
    ]

    placement_constraint_details = [
      for p in local.instance.placement_constraint_details : {
        compute_bare_metal_host_id = p.compute_bare_metal_host_id
        compute_host_group_id      = p.compute_host_group_id
        type                       = p.type
      }
    ]

    platform_config = try({
      are_virtual_instructions_enabled               = one(local.instance.platform_config).are_virtual_instructions_enabled
      config_map                                     = one(local.instance.platform_config).config_map
      is_access_control_service_enabled              = one(local.instance.platform_config).is_access_control_service_enabled
      is_input_output_memory_management_unit_enabled = one(local.instance.platform_config).is_input_output_memory_management_unit_enabled
      is_measured_boot_enabled                       = one(local.instance.platform_config).is_measured_boot_enabled
      is_memory_encryption_enabled                   = one(local.instance.platform_config).is_memory_encryption_enabled
      is_secure_boot_enabled                         = one(local.instance.platform_config).is_secure_boot_enabled
      is_symmetric_multi_threading_enabled           = one(local.instance.platform_config).is_symmetric_multi_threading_enabled
      is_trusted_platform_module_enabled             = one(local.instance.platform_config).is_trusted_platform_module_enabled
      numa_nodes_per_socket                          = one(local.instance.platform_config).numa_nodes_per_socket
      percentage_of_cores_enabled                    = one(local.instance.platform_config).percentage_of_cores_enabled
      type                                           = one(local.instance.platform_config).type
    }, null)

    preemptible_instance_config = try({
      preemption_action = {
        preserve_boot_volume = one(local.instance.preemptible_instance_config).preemption_action[0].preserve_boot_volume
        type                 = one(local.instance.preemptible_instance_config).preemption_action[0].type
      }
    }, null)

    shape_config = try({
      baseline_ocpu_utilization     = one(local.instance.shape_config).baseline_ocpu_utilization
      gpu_description               = one(local.instance.shape_config).gpu_description
      gpus                          = one(local.instance.shape_config).gpus
      local_disk_description        = one(local.instance.shape_config).local_disk_description
      local_disks                   = one(local.instance.shape_config).local_disks
      local_disks_total_size_in_gbs = one(local.instance.shape_config).local_disks_total_size_in_gbs
      local_volume_size_in_gbs      = one(local.instance.shape_config).local_volume_size_in_gbs
      max_vnic_attachments          = one(local.instance.shape_config).max_vnic_attachments
      memory_in_gbs                 = one(local.instance.shape_config).memory_in_gbs
      networking_bandwidth_in_gbps  = one(local.instance.shape_config).networking_bandwidth_in_gbps
      nvmes                         = one(local.instance.shape_config).nvmes
      ocpus                         = one(local.instance.shape_config).ocpus
      processor_description         = one(local.instance.shape_config).processor_description
      resource_management           = one(local.instance.shape_config).resource_management
      vcpus                         = one(local.instance.shape_config).vcpus
    }, null)

    source_details = try({
      boot_volume_size_in_gbs         = one(local.instance.source_details).boot_volume_size_in_gbs
      boot_volume_vpus_per_gb         = one(local.instance.source_details).boot_volume_vpus_per_gb
      is_preserve_boot_volume_enabled = one(local.instance.source_details).is_preserve_boot_volume_enabled
      kms_key_id                      = one(local.instance.source_details).kms_key_id
      source_id                       = one(local.instance.source_details).source_id
      source_type                     = one(local.instance.source_details).source_type
      instance_source_image_filter_details = try({
        compartment_id           = one(one(local.instance.source_details).instance_source_image_filter_details).compartment_id
        defined_tags_filter      = one(one(local.instance.source_details).instance_source_image_filter_details).defined_tags_filter
        operating_system         = one(one(local.instance.source_details).instance_source_image_filter_details).operating_system
        operating_system_version = one(one(local.instance.source_details).instance_source_image_filter_details).operating_system_version
      }, null)
    }, null)
  }, null)
}

################################################################################
# NSG
################################################################################

output "nsg_id" {
  description = "The OCID of the Network Security Group created by this module. Null when create_nsg = false"
  value       = try(oci_core_network_security_group.this[0].id, null)
}

output "nsg_all_attributes" {
  description = "All attributes of the created NSG (full object, auto-updating)"
  value       = { for k, v in oci_core_network_security_group.this : k => v }
}

################################################################################
# Block Volumes
################################################################################

output "block_volumes" {
  description = "Map of block volume name to attributes: {id, availability_domain, size_in_gbs}"
  value = {
    for k, v in oci_core_volume.this :
    k => {
      id                  = v.id
      availability_domain = v.availability_domain
      size_in_gbs         = v.size_in_gbs
    }
  }
}

output "block_volume_attachments" {
  description = "Map of block volume name to volume attachment attributes"
  value       = { for k, v in oci_core_volume_attachment.this : k => v }
}

################################################################################
# Secondary Network Interfaces
################################################################################

output "secondary_vnic_attachments" {
  description = "Map of secondary network interface name to VNIC attachment attributes (full object, auto-updating)"
  value       = { for k, v in oci_core_vnic_attachment.this : k => v }
}

output "secondary_network_interfaces" {
  description = "Map of secondary network interface name to resolved attributes: {vnic_id, nic_index, private_ip, public_ip, mac_address}"
  value = {
    for k, v in oci_core_vnic_attachment.this :
    k => {
      vnic_id     = v.vnic_id
      nic_index   = v.nic_index
      private_ip  = try(data.oci_core_vnic.secondary[k].private_ip_address, null)
      public_ip   = try(data.oci_core_vnic.secondary[k].public_ip_address, null)
      mac_address = try(data.oci_core_vnic.secondary[k].mac_address, null)
    }
  }
}

################################################################################
# Reserved Public IP
################################################################################

output "reserved_public_ip" {
  description = "All attributes of the reserved public IP resource. Null when create_reserved_public_ip = false"
  value       = try(oci_core_public_ip.this[0], null)
}

output "reserved_public_ip_address" {
  description = "The reserved public IP address string. Null when not created"
  value       = try(oci_core_public_ip.this[0].ip_address, null)
}

################################################################################
# Windows
################################################################################

output "instance_credentials" {
  description = "Initial Windows credentials fetched from OCI (username + password). Only populated when is_windows_instance = true"
  sensitive   = true
  value = try({
    username = data.oci_core_instance_credentials.this[0].username
    password = data.oci_core_instance_credentials.this[0].password
  }, null)
}

################################################################################
# Static values (arguments)
################################################################################

output "name" {
  description = "The name specified as argument to this module"
  value       = var.name
}

output "resolved_availability_domain" {
  description = "The resolved availability domain name (e.g. \"abCD:US-ASHBURN-AD-1\")"
  value       = local.availability_domain
}
