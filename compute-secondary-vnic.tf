################################################################################
# Secondary Network Interfaces  (maps to secondary_network_interface)
################################################################################

resource "oci_core_vnic_attachment" "this" {
  for_each = local.create ? var.secondary_network_interface : {}

  instance_id  = local.instance.id
  display_name = coalesce(each.value.display_name, "${var.name}-${each.key}")
  nic_index    = each.value.nic_index

  create_vnic_details {
    subnet_id                 = each.value.subnet_id
    private_ip                = each.value.private_ip
    assign_public_ip          = each.value.assign_public_ip
    assign_ipv6ip             = each.value.assign_ipv6ip
    assign_private_dns_record = each.value.assign_private_dns_record
    hostname_label            = each.value.hostname_label
    skip_source_dest_check    = each.value.skip_source_dest_check
    nsg_ids                   = each.value.nsg_ids
    display_name              = coalesce(each.value.display_name, "${var.name}-${each.key}")

    freeform_tags = merge(
      { "Name" = coalesce(each.value.display_name, "${var.name}-${each.key}") },
      var.tags,
      each.value.tags,
    )
    defined_tags = merge(var.defined_tags, each.value.defined_tags)
  }

  depends_on = [
    oci_core_instance.this,
    oci_core_instance.ignore_image,
  ]

  lifecycle {
    ignore_changes = [
      create_vnic_details[0].defined_tags,
      create_vnic_details[0].freeform_tags,
    ]
  }
}

# Resolved VNIC details (private/public IP, MAC) for each secondary attachment.
data "oci_core_vnic" "secondary" {
  for_each = local.create ? var.secondary_network_interface : {}

  vnic_id = oci_core_vnic_attachment.this[each.key].vnic_id
}

################################################################################
# Reserved Public IP per secondary VNIC  (AWS has no per-secondary-interface EIP)
################################################################################

locals {
  secondary_network_interface_with_reserved_ip = local.create ? {
    for k, v in var.secondary_network_interface : k => v if v.create_reserved_public_ip
  } : {}
}

# Secondary private IP - required to attach a reserved public IP to a secondary VNIC.
data "oci_core_private_ips" "secondary" {
  for_each = local.secondary_network_interface_with_reserved_ip

  vnic_id = oci_core_vnic_attachment.this[each.key].vnic_id

  depends_on = [oci_core_vnic_attachment.this]
}

resource "oci_core_public_ip" "secondary" {
  for_each = local.secondary_network_interface_with_reserved_ip

  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "${var.name}-${each.key}-public-ip"

  private_ip_id = data.oci_core_private_ips.secondary[each.key].private_ips[0].id

  freeform_tags = merge(
    { "Name" = "${var.name}-${each.key}-public-ip" },
    var.tags,
    each.value.reserved_public_ip_tags,
  )
  defined_tags = merge(var.defined_tags, each.value.defined_tags)

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}
