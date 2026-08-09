provider "oci" {
  region = local.region
}

locals {
  name   = "ex-simple"
  region = "us-ashburn-1"

  vcn_cidr = "10.0.0.0/16"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-compute-instance"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# VCN (supporting resource)
################################################################################

module "vcn" {
  source  = "terraform-oci-modules/vcn/oci"
  version = "~> 0.7"

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
# Compute Instance Module
################################################################################

module "instance" {
  source = "../../"

  name           = local.name
  compartment_id = var.compartment_id

  source_id = data.oci_core_images.oracle_linux.images[0].id

  # Shape - VM.Standard.E4.Flex with 1 OCPU / 8 GB RAM
  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 1
    memory_in_gbs = 8
  }

  availability_domain = 1

  # Networking - private subnet from VCN module
  subnet_id = module.vcn.private_subnets[0]

  ssh_authorized_keys = var.ssh_public_key

  tags = local.tags
}
