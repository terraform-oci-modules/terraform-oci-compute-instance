locals {
  create = var.create

  # Resolve AD number (1/2/3) → full tenancy-specific AD name.
  availability_domains = data.oci_identity_availability_domains.this.availability_domains
  availability_domain  = local.availability_domains[var.availability_domain - 1].name

  # Flex shape detection - shapes ending in ".Flex" require shape_config block.
  shape_is_flex = can(regex("\\.Flex$", var.shape))

  # Merged NSG list: user-supplied existing NSGs + the NSG created by this module.
  all_nsg_ids = compact(concat(
    var.nsg_ids,
    var.create_nsg ? [oci_core_network_security_group.this[0].id] : []
  ))

  # Canonical instance reference - works whether lifecycle ignore or not.
  instance = try(
    oci_core_instance.ignore_image[0],
    oci_core_instance.this[0],
    null
  )

  # Cloud-agent plugin list, merging defaults with user overrides.
  # OCI API uses exact plugin names; map keys use underscored aliases for HCL ergonomics.
  plugin_name_map = {
    monitoring              = "Compute Instance Monitoring"
    bastion                 = "Bastion"
    run_command             = "Run Command"
    osms                    = "OS Management Service Agent"
    custom_logs             = "Custom Logs Monitoring"
    vulnerability_scanning  = "Vulnerability Scanning"
    block_volume_mgmt       = "Block Volume Management"
    management              = "Management Agent"
    java_management_service = "Java Management Service"
    autonomous_linux        = "Oracle Autonomous Linux"
  }

  resolved_plugins = {
    for alias, state in var.cloud_agent_plugins :
    lookup(local.plugin_name_map, alias, alias) => state
  }

  # Freeform tag merge helpers
  instance_tags = merge(
    { "Name" = var.name },
    var.tags,
    var.instance_tags,
  )
  instance_defined_tags = merge(var.defined_tags, var.instance_defined_tags)

}

################################################################################
# Data Sources
################################################################################

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

# VNIC attachments - needed to look up primary VNIC details (public IP, VNIC ID).
data "oci_core_vnic_attachments" "this" {
  count = local.create ? 1 : 0

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  instance_id         = local.instance.id

  depends_on = [
    oci_core_instance.this,
    oci_core_instance.ignore_image,
  ]
}

# Primary private IP - required to attach a reserved public IP to the VNIC.
data "oci_core_private_ips" "this" {
  count = local.create && var.create_reserved_public_ip ? 1 : 0

  vnic_id = data.oci_core_vnic_attachments.this[0].vnic_attachments[0].vnic_id

  depends_on = [data.oci_core_vnic_attachments.this]
}

# Windows instance credentials (username + encrypted password).
data "oci_core_instance_credentials" "this" {
  count = local.create && var.is_windows_instance ? 1 : 0

  instance_id = local.instance.id

  depends_on = [
    oci_core_instance.this,
    oci_core_instance.ignore_image,
  ]
}

################################################################################
# Instance - standard (tracks image changes)
################################################################################

resource "oci_core_instance" "this" {
  count = local.create && !var.ignore_image_changes ? 1 : 0

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = var.name
  shape               = var.shape

  dynamic "shape_config" {
    for_each = local.shape_is_flex ? [var.shape_config] : []
    content {
      ocpus                     = shape_config.value.ocpus
      memory_in_gbs             = shape_config.value.memory_in_gbs
      baseline_ocpu_utilization = shape_config.value.baseline_ocpu_utilization
    }
  }

  source_details {
    source_id               = var.source_id
    source_type             = var.source_type
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
    kms_key_id              = var.boot_volume_kms_key_id
  }

  create_vnic_details {
    subnet_id              = var.subnet_id
    assign_public_ip       = var.assign_public_ip
    assign_ipv6ip          = var.assign_ipv6ip
    private_ip             = var.private_ip
    hostname_label         = var.hostname_label
    skip_source_dest_check = !var.source_dest_check
    nsg_ids                = local.all_nsg_ids
    display_name           = var.name

    dynamic "ipv6address_ipv6subnet_cidr_pair_details" {
      for_each = var.ipv6address_ipv6subnet_cidr_pair_details
      content {
        ipv6subnet_cidr = ipv6address_ipv6subnet_cidr_pair_details.value.ipv6subnet_cidr
        ipv6address     = ipv6address_ipv6subnet_cidr_pair_details.value.ipv6address
      }
    }
  }

  metadata = merge(
    var.ssh_authorized_keys != null ? { ssh_authorized_keys = var.ssh_authorized_keys } : {},
    var.user_data != null ? { user_data = var.user_data } : {},
    var.extended_metadata,
  )

  agent_config {
    is_monitoring_disabled   = var.is_monitoring_disabled
    is_management_disabled   = var.is_management_disabled
    are_all_plugins_disabled = var.are_all_plugins_disabled

    dynamic "plugins_config" {
      for_each = local.resolved_plugins
      content {
        name          = plugins_config.key
        desired_state = plugins_config.value
      }
    }
  }

  dynamic "availability_config" {
    for_each = var.instance_initiated_shutdown_behavior != null ? [1] : []
    content {
      recovery_action = var.instance_initiated_shutdown_behavior
    }
  }

  dynamic "preemptible_instance_config" {
    for_each = var.preemptible_instance_config != null ? [var.preemptible_instance_config] : []
    content {
      preemption_action {
        type                 = preemptible_instance_config.value.action
        preserve_boot_volume = lookup(preemptible_instance_config.value, "preserve_boot_volume_on_termination", false)
      }
    }
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = var.metadata_options.is_http_tokens_enabled
  }

  dedicated_vm_host_id                = var.dedicated_vm_host_id
  capacity_reservation_id             = var.capacity_reservation_id
  fault_domain                        = var.fault_domain
  is_pv_encryption_in_transit_enabled = var.is_pv_encryption_in_transit_enabled
  ipxe_script                         = var.ipxe_script
  state                               = var.instance_state
  preserve_boot_volume                = var.preserve_boot_volume

  freeform_tags = local.instance_tags
  defined_tags  = local.instance_defined_tags

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [var.timeouts] : []
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

################################################################################
# Instance - ignore image/source changes (maps to ignore_ami_changes)
################################################################################

resource "oci_core_instance" "ignore_image" {
  count = local.create && var.ignore_image_changes ? 1 : 0

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = var.name
  shape               = var.shape

  dynamic "shape_config" {
    for_each = local.shape_is_flex ? [var.shape_config] : []
    content {
      ocpus                     = shape_config.value.ocpus
      memory_in_gbs             = shape_config.value.memory_in_gbs
      baseline_ocpu_utilization = shape_config.value.baseline_ocpu_utilization
    }
  }

  source_details {
    source_id               = var.source_id
    source_type             = var.source_type
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
    kms_key_id              = var.boot_volume_kms_key_id
  }

  create_vnic_details {
    subnet_id              = var.subnet_id
    assign_public_ip       = var.assign_public_ip
    assign_ipv6ip          = var.assign_ipv6ip
    private_ip             = var.private_ip
    hostname_label         = var.hostname_label
    skip_source_dest_check = !var.source_dest_check
    nsg_ids                = local.all_nsg_ids
    display_name           = var.name

    dynamic "ipv6address_ipv6subnet_cidr_pair_details" {
      for_each = var.ipv6address_ipv6subnet_cidr_pair_details
      content {
        ipv6subnet_cidr = ipv6address_ipv6subnet_cidr_pair_details.value.ipv6subnet_cidr
        ipv6address     = ipv6address_ipv6subnet_cidr_pair_details.value.ipv6address
      }
    }
  }

  metadata = merge(
    var.ssh_authorized_keys != null ? { ssh_authorized_keys = var.ssh_authorized_keys } : {},
    var.user_data != null ? { user_data = var.user_data } : {},
    var.extended_metadata,
  )

  agent_config {
    is_monitoring_disabled   = var.is_monitoring_disabled
    is_management_disabled   = var.is_management_disabled
    are_all_plugins_disabled = var.are_all_plugins_disabled

    dynamic "plugins_config" {
      for_each = local.resolved_plugins
      content {
        name          = plugins_config.key
        desired_state = plugins_config.value
      }
    }
  }

  dynamic "availability_config" {
    for_each = var.instance_initiated_shutdown_behavior != null ? [1] : []
    content {
      recovery_action = var.instance_initiated_shutdown_behavior
    }
  }

  dynamic "preemptible_instance_config" {
    for_each = var.preemptible_instance_config != null ? [var.preemptible_instance_config] : []
    content {
      preemption_action {
        type                 = preemptible_instance_config.value.action
        preserve_boot_volume = lookup(preemptible_instance_config.value, "preserve_boot_volume_on_termination", false)
      }
    }
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = var.metadata_options.is_http_tokens_enabled
  }

  dedicated_vm_host_id                = var.dedicated_vm_host_id
  capacity_reservation_id             = var.capacity_reservation_id
  fault_domain                        = var.fault_domain
  is_pv_encryption_in_transit_enabled = var.is_pv_encryption_in_transit_enabled
  ipxe_script                         = var.ipxe_script
  state                               = var.instance_state
  preserve_boot_volume                = var.preserve_boot_volume

  freeform_tags = local.instance_tags
  defined_tags  = local.instance_defined_tags

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [var.timeouts] : []
    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags, source_details]
  }
}

################################################################################
# Reserved Public IP  (maps to Elastic IP / EIP)
################################################################################

resource "oci_core_public_ip" "this" {
  # Create a new reserved IP, OR skip creation when attaching an existing one.
  count = local.create && var.create_reserved_public_ip ? 1 : 0

  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "${var.name}-public-ip"

  # Attach immediately to the primary private IP of the instance VNIC.
  private_ip_id = data.oci_core_private_ips.this[0].private_ips[0].id

  freeform_tags = merge({ "Name" = "${var.name}-public-ip" }, var.tags, var.reserved_public_ip_tags)
  defined_tags  = var.defined_tags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}
