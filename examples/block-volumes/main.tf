provider "oci" {
  region = local.region
}

locals {
  name   = "ex-block-volumes"
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
# Image — latest Oracle Linux 9 compatible with VM.Standard.E4.Flex
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
# Compute Instance Module — Block Volumes example
################################################################################

module "instance" {
  source = "../../"

  name           = local.name
  compartment_id = var.compartment_id
  source_id      = data.oci_core_images.oracle_linux.images[0].id
  subnet_id      = module.vcn.private_subnets[0]

  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 2
    memory_in_gbs = 16
  }

  availability_domain = 1
  ssh_authorized_keys = var.ssh_public_key

  # Block volumes — maps to ebs_block_device in AWS
  block_volumes = {
    # Paravirtualized — simplest attachment, no manual OS-level setup
    "data" = {
      size_in_gbs     = 500
      vpus_per_gb     = 20 # Higher performance
      backup_policy   = "silver"
      attachment_type = "paravirtualized"
      tags            = { "Purpose" = "application-data" }
    }
    # Low-cost archive storage
    "archive" = {
      size_in_gbs     = 2000
      vpus_per_gb     = 0 # Lower Cost tier
      attachment_type = "paravirtualized"
    }
    # iSCSI — required for some performance-sensitive or bare metal workloads
    "database" = {
      size_in_gbs     = 1000
      vpus_per_gb     = 30 # Ultra High Performance
      backup_policy   = "gold"
      attachment_type = "iscsi"
      tags            = { "Purpose" = "database-data" }
    }
  }

  tags = local.tags
}
