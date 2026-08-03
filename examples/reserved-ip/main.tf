provider "oci" {
  region = local.region
}

locals {
  name   = "ex-reserved-ip"
  region = "us-ashburn-1"

  vcn_cidr = "10.0.0.0/16"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-compute-instance"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# VCN (supporting resource) - public subnet so reserved IPs are reachable
################################################################################

module "vcn" {
  source  = "terraform-oci-modules/vcn/oci"
  version = "~> 0.6"

  name           = local.name
  compartment_id = var.compartment_id
  vcn_cidr_block = local.vcn_cidr

  public_subnets = [cidrsubnet(local.vcn_cidr, 4, 8)]

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
# Instance with a reserved public IP  (maps to create_eip = true in AWS)
################################################################################

module "instance" {
  source = "../../"

  name           = local.name
  compartment_id = var.compartment_id
  source_id      = data.oci_core_images.oracle_linux.images[0].id
  subnet_id      = module.vcn.public_subnets[0]

  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 1
    memory_in_gbs = 8
  }

  availability_domain = 1
  ssh_authorized_keys = var.ssh_public_key

  # Create a reserved (static) public IP - survives instance replacement.
  # Maps to create_eip = true in the AWS module.
  create_reserved_public_ip = true
  reserved_public_ip_tags = {
    "Purpose" = "stable-ingress"
  }

  tags = local.tags
}
