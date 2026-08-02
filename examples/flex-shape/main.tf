provider "oci" {
  region = local.region
}

locals {
  name   = "ex-flex-shape"
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
# Standard Flex Shape (full OCPU baseline)
################################################################################

module "standard_flex" {
  source = "../../"

  name           = "${local.name}-standard"
  compartment_id = var.compartment_id
  source_id      = data.oci_core_images.oracle_linux.images[0].id
  subnet_id      = module.vcn.private_subnets[0]

  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 2
    memory_in_gbs = 16
    # baseline_ocpu_utilization omitted → BASELINE_1_1 (100% baseline)
  }

  availability_domain = 1
  tags                = local.tags
}

################################################################################
# Burstable Flex Shape - 50% baseline (maps to AWS t-series cpu_credits=standard)
################################################################################

module "burstable_flex" {
  source = "../../"

  name           = "${local.name}-burstable"
  compartment_id = var.compartment_id
  source_id      = data.oci_core_images.oracle_linux.images[0].id
  subnet_id      = module.vcn.private_subnets[0]

  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus                     = 1
    memory_in_gbs             = 8
    baseline_ocpu_utilization = "BASELINE_1_2" # 50% baseline
  }

  availability_domain = 1
  tags                = local.tags
}

################################################################################
# Micro Burstable - 12.5% baseline (smallest burstable tier)
################################################################################

module "micro_flex" {
  source = "../../"

  name           = "${local.name}-micro"
  compartment_id = var.compartment_id
  source_id      = data.oci_core_images.oracle_linux.images[0].id
  subnet_id      = module.vcn.private_subnets[0]

  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus                     = 1
    memory_in_gbs             = 6
    baseline_ocpu_utilization = "BASELINE_1_8" # 12.5% baseline
  }

  availability_domain = 1
  tags                = local.tags
}
