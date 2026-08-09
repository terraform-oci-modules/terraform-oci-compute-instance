################################################################################
# Boot Volume Backup Policy
################################################################################

data "oci_core_volume_backup_policies" "this" {
  count = local.create && (
    var.boot_volume.backup_policy != "disabled" ||
    anytrue([for v in var.block_volumes : v.backup_policy != "disabled"])
  ) ? 1 : 0
}

locals {
  # Map user-friendly policy name to OCI's predefined policy OCID.
  # OCI ships three predefined policies: gold, silver, bronze.
  # The data source returns all available policies; we find ours by display_name.
  backup_policy_id = (
    var.boot_volume.backup_policy == "disabled"
    ? null
    : try(
      [
        for p in data.oci_core_volume_backup_policies.this[0].volume_backup_policies :
        p.id if lower(p.display_name) == var.boot_volume.backup_policy
      ][0],
      null
    )
  )
}

resource "oci_core_volume_backup_policy_assignment" "boot" {
  count = local.create && local.backup_policy_id != null ? 1 : 0

  asset_id  = local.instance.boot_volume_id
  policy_id = local.backup_policy_id

  depends_on = [
    oci_core_instance.this,
    oci_core_instance.ignore_image,
  ]
}

################################################################################
# Block Volumes  (maps to ebs_volumes)
################################################################################

resource "oci_core_volume" "this" {
  for_each = local.create ? var.block_volumes : {}

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${var.name}-${each.key}"

  size_in_gbs = each.value.size_in_gbs
  vpus_per_gb = each.value.vpus_per_gb
  kms_key_id  = each.value.kms_key_id

  freeform_tags = merge(
    { "Name" = "${var.name}-${each.key}" },
    var.tags,
    each.value.tags,
  )
  defined_tags = merge(var.defined_tags, each.value.defined_tags)

  lifecycle {
    ignore_changes = [defined_tags, freeform_tags]
  }
}

resource "oci_core_volume_backup_policy_assignment" "block" {
  for_each = {
    for k, v in var.block_volumes :
    k => v
    if local.create && v.backup_policy != "disabled"
  }

  asset_id = oci_core_volume.this[each.key].id
  policy_id = try(
    [
      for p in data.oci_core_volume_backup_policies.this[0].volume_backup_policies :
      p.id if lower(p.display_name) == each.value.backup_policy
    ][0],
    null
  )
}

resource "oci_core_volume_attachment" "this" {
  for_each = local.create ? var.block_volumes : {}

  instance_id     = local.instance.id
  volume_id       = oci_core_volume.this[each.key].id
  attachment_type = each.value.attachment_type
  display_name    = "${var.name}-${each.key}-attachment"

  # iSCSI-specific: require CHAP auth when using iSCSI attachment type
  use_chap = each.value.attachment_type == "iscsi" ? true : null

  depends_on = [
    oci_core_instance.this,
    oci_core_instance.ignore_image,
  ]
}
