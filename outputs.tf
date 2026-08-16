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
  # 3 top-level attributes on oci_core_instance are deprecated
  # (hostname_label, image, subnet_id) - see the hostname_label/image_id
  # outputs above and create_vnic_details.subnet_id below for their
  # non-deprecated equivalents. Filtering by key here (rather than reading
  # local.instance wholesale, or reconstructing every other field by hand)
  # avoids ever evaluating those 3 attributes' values at all, which is what
  # actually triggers the provider's deprecation warning - not merely their
  # presence in the final output. try(..., null) rather than an
  # `== null ? null : ...` guard for the same reason: the equality
  # comparison would itself read local.instance wholesale.
  description = "Attributes of the created instance, excluding 3 deprecated top-level fields (hostname_label, image, subnet_id) whose non-deprecated equivalents are included under create_vnic_details/source_details"
  sensitive   = true
  value = try({
    for k, v in local.instance : k => v if !contains(["hostname_label", "image", "subnet_id"], k)
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
