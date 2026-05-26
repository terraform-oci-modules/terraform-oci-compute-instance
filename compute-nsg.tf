################################################################################
# Network Security Group  (maps to security_group_* / create_security_group)
################################################################################

resource "oci_core_network_security_group" "this" {
  count = local.create && var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.nsg_vcn_id
  display_name   = coalesce(var.nsg_name, "${var.name}-nsg")

  freeform_tags = merge(
    { "Name" = coalesce(var.nsg_name, "${var.name}-nsg") },
    var.tags,
    var.nsg_tags,
  )
  defined_tags = var.defined_tags

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_core_network_security_group_security_rule" "ingress" {
  for_each = local.create && var.create_nsg ? var.nsg_ingress_rules : {}

  network_security_group_id = oci_core_network_security_group.this[0].id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source                    = each.value.source
  source_type               = each.value.source_type
  description               = lookup(each.value, "description", null)

  dynamic "tcp_options" {
    for_each = try(each.value.tcp_options, null) != null ? [each.value.tcp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = try(tcp_options.value.destination_port_range, null) != null ? [tcp_options.value.destination_port_range] : []
        content {
          min = destination_port_range.value.min
          max = destination_port_range.value.max
        }
      }
      dynamic "source_port_range" {
        for_each = try(tcp_options.value.source_port_range, null) != null ? [tcp_options.value.source_port_range] : []
        content {
          min = source_port_range.value.min
          max = source_port_range.value.max
        }
      }
    }
  }

  dynamic "udp_options" {
    for_each = try(each.value.udp_options, null) != null ? [each.value.udp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = try(udp_options.value.destination_port_range, null) != null ? [udp_options.value.destination_port_range] : []
        content {
          min = destination_port_range.value.min
          max = destination_port_range.value.max
        }
      }
      dynamic "source_port_range" {
        for_each = try(udp_options.value.source_port_range, null) != null ? [udp_options.value.source_port_range] : []
        content {
          min = source_port_range.value.min
          max = source_port_range.value.max
        }
      }
    }
  }

  dynamic "icmp_options" {
    for_each = try(each.value.icmp_options, null) != null ? [each.value.icmp_options] : []
    content {
      type = icmp_options.value.type
      code = lookup(icmp_options.value, "code", null)
    }
  }
}

resource "oci_core_network_security_group_security_rule" "egress" {
  for_each = local.create && var.create_nsg ? var.nsg_egress_rules : {}

  network_security_group_id = oci_core_network_security_group.this[0].id
  direction                 = "EGRESS"
  protocol                  = each.value.protocol
  destination               = each.value.destination
  destination_type          = each.value.destination_type
  description               = lookup(each.value, "description", null)

  dynamic "tcp_options" {
    for_each = try(each.value.tcp_options, null) != null ? [each.value.tcp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = try(tcp_options.value.destination_port_range, null) != null ? [tcp_options.value.destination_port_range] : []
        content {
          min = destination_port_range.value.min
          max = destination_port_range.value.max
        }
      }
    }
  }

  dynamic "udp_options" {
    for_each = try(each.value.udp_options, null) != null ? [each.value.udp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = try(udp_options.value.destination_port_range, null) != null ? [udp_options.value.destination_port_range] : []
        content {
          min = destination_port_range.value.min
          max = destination_port_range.value.max
        }
      }
    }
  }

  dynamic "icmp_options" {
    for_each = try(each.value.icmp_options, null) != null ? [each.value.icmp_options] : []
    content {
      type = icmp_options.value.type
      code = lookup(icmp_options.value, "code", null)
    }
  }
}
