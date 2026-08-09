provider "oci" {
  region = local.region
}

locals {
  name   = "ex-ipv6"
  region = "us-ashburn-1"

  vcn_cidr = "10.0.0.0/16"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-compute-instance"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# VCN (supporting resource - IPv6 enabled)
#
# enable_ipv6 = true causes OCI to assign a /56 prefix and the module
# automatically derives a /64 for every subnet. Single apply - no manual CIDR
# input and no -target step required.
################################################################################

module "vcn" {
  source  = "terraform-oci-modules/vcn/oci"
  version = "~> 0.7"

  name           = local.name
  compartment_id = var.compartment_id
  vcn_cidr_block = local.vcn_cidr

  enable_ipv6    = true
  public_subnets = [cidrsubnet(local.vcn_cidr, 4, 0)]

  create_igw = true

  tags = local.tags
}

################################################################################
# Image - latest Oracle Linux 9 compatible with VM.Standard.E4.Flex
################################################################################

data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "9"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

################################################################################
# Compute Instance - dual-stack (public IPv4 + auto-assigned IPv6)
################################################################################

module "instance" {
  source = "../../"

  name           = local.name
  compartment_id = var.compartment_id

  source_id = data.oci_core_images.oracle_linux.images[0].id

  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 1
    memory_in_gbs = 8
  }

  availability_domain = 1

  subnet_id        = module.vcn.public_subnets[0]
  assign_public_ip = true

  # Auto-assign an IPv6 address from the subnet's /64 CIDR pool.
  # Maps to enable_primary_ipv6 / ipv6_address_count in the AWS module.
  assign_ipv6ip = true

  ssh_authorized_keys = var.ssh_public_key

  tags = local.tags

  depends_on = [module.vcn]
}
