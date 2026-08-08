provider "oci" {
  region = local.region
}

locals {
  name   = "ex-windows"
  region = "us-ashburn-1"

  vcn_cidr = "10.0.0.0/16"

  tags = {
    Example    = local.name
    GithubRepo = "terraform-oci-compute-instance"
    GithubOrg  = "terraform-oci-modules"
  }
}

################################################################################
# VCN (supporting resource) - public subnet with IGW for RDP access
################################################################################

module "vcn" {
  source  = "terraform-oci-modules/vcn/oci"
  version = "~> 0.7"

  name           = local.name
  compartment_id = var.compartment_id
  vcn_cidr_block = local.vcn_cidr

  public_subnets = [cidrsubnet(local.vcn_cidr, 4, 8)]

  create_igw = true

  tags = local.tags
}

################################################################################
# Image - latest Windows Server 2022 Standard compatible with VM.Standard.E4.Flex
################################################################################

data "oci_core_images" "windows" {
  compartment_id           = var.compartment_id
  operating_system         = "Windows"
  operating_system_version = "Server 2022 Standard"
  shape                    = "VM.Standard.E4.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

################################################################################
# Compute Instance Module - Windows example
################################################################################

module "instance" {
  source = "../../"

  name           = local.name
  compartment_id = var.compartment_id

  source_id = data.oci_core_images.windows.images[0].id

  # Shape - Windows requires at least 1 OCPU and 8 GB RAM
  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 2
    memory_in_gbs = 16
  }

  availability_domain = 1

  # Public subnet + ephemeral public IP for direct RDP access (port 3389)
  subnet_id        = module.vcn.public_subnets[0]
  assign_public_ip = true

  # Windows instance flag - enables credential data source fetch.
  # Maps to get_password_data = true in AWS.
  is_windows_instance = true

  # Boot volume - Windows benefits from higher performance storage
  boot_volume_size_in_gbs   = 256
  boot_volume_vpus_per_gb   = 20
  boot_volume_backup_policy = "silver"

  # Windows does not support the Run Command plugin - omit it entirely.
  cloud_agent_plugins = {
    monitoring = "ENABLED"
    bastion    = "DISABLED"
  }

  tags = local.tags
}
