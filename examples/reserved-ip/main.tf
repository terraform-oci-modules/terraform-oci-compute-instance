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
# VCN (supporting resource) - two public subnets so reserved IPs are reachable
# on both the primary and secondary interface
################################################################################

module "vcn" {
  source  = "terraform-oci-modules/vcn/oci"
  version = "~> 0.7"

  name           = local.name
  compartment_id = var.compartment_id
  vcn_cidr_block = local.vcn_cidr

  public_subnets = [
    cidrsubnet(local.vcn_cidr, 4, 8),
    cidrsubnet(local.vcn_cidr, 4, 9),
  ]

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

  # Secondary VNIC with its own reserved public IP. The AWS module has no
  # equivalent - create_eip only covers the primary interface there.
  secondary_network_interface = {
    "data" = {
      subnet_id                 = module.vcn.public_subnets[1]
      create_reserved_public_ip = true
      reserved_public_ip_tags = {
        "Purpose" = "stable-egress-secondary"
      }
    }
  }

  tags = local.tags

  depends_on = [module.vcn]
}
