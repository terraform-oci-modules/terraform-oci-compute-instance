provider "oci" {
  region = local.region
}

locals {
  name   = "ex-capacity-reservation"
  region = "us-ashburn-1"

  vcn_cidr = "10.0.0.0/16"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-compute-instance"
    GithubOrg  = "terraform-oci-modules"
  }
}

# Resolve AD name — required by the capacity reservation resource.
# The compute module handles this internally via availability_domain (integer);
# here we need the string form for the oci_core_compute_capacity_reservation resource.
data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

locals {
  availability_domain = data.oci_identity_availability_domains.this.availability_domains[0].name
}

################################################################################
# VCN (supporting resource)
################################################################################

module "vcn" {
  source  = "terraform-oci-modules/vcn/oci"
  version = "~> 0.5"

  name           = local.name
  compartment_id = var.compartment_id
  vcn_cidr_block = local.vcn_cidr

  private_subnets = [cidrsubnet(local.vcn_cidr, 4, 0)]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  create_service_gateway = true

  tags = local.tags
}

################################################################################
# Image — latest Oracle Linux 9 compatible with VM.Standard.E6.Flex
################################################################################

data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.E6.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

################################################################################
# Capacity Reservation
#
# Reserves capacity for 1 × VM.Standard.E6.Flex (1 OCPU / 6 GB) in AD-1.
# The instance shape and shape_config must match instance_reservation_configs.
################################################################################

resource "oci_core_compute_capacity_reservation" "this" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = "${local.name}-reservation"

  instance_reservation_configs {
    instance_shape = "VM.Standard.E6.Flex"
    reserved_count = 1

    instance_shape_config {
      ocpus         = 1
      memory_in_gbs = 6
    }
  }

  freeform_tags = local.tags
}

################################################################################
# Compute Instance — launched into the capacity reservation
################################################################################

module "instance" {
  source = "../../"

  name           = local.name
  compartment_id = var.compartment_id

  source_id = data.oci_core_images.oracle_linux.images[0].id

  # Shape must match the reservation's instance_reservation_configs exactly.
  shape = "VM.Standard.E6.Flex"
  shape_config = {
    ocpus         = 1
    memory_in_gbs = 6
  }

  availability_domain = 1

  subnet_id = module.vcn.private_subnets[0]

  ssh_authorized_keys = var.ssh_public_key

  # Target the capacity reservation — OCI will use the reserved slot instead of
  # consuming on-demand capacity. Maps to capacity_reservation_specification in AWS.
  capacity_reservation_id = oci_core_compute_capacity_reservation.this.id

  tags = local.tags
}
