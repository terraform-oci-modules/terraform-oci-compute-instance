provider "oci" {
  region = local.region
}

locals {
  name   = "ex-complete"
  region = "us-ashburn-1"

  vcn_cidr = "10.0.0.0/16"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "Hello from cloud-init" >> /var/log/cloud-init-output.log
    yum update -y
  EOF
  )

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

  private_subnets = [cidrsubnet(local.vcn_cidr, 4, 0), cidrsubnet(local.vcn_cidr, 4, 1)]
  public_subnets  = [cidrsubnet(local.vcn_cidr, 4, 8)]

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
# Compute Instance Module — Complete example
################################################################################

module "instance" {
  source = "../../"

  name           = local.name
  compartment_id = var.compartment_id

  source_id            = data.oci_core_images.oracle_linux.images[0].id
  ignore_image_changes = false

  # Shape — 4 OCPU / 32 GB Flex
  shape = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 4
    memory_in_gbs = 32
  }

  availability_domain = 1

  # Networking — private subnet from VCN module
  subnet_id         = module.vcn.private_subnets[0]
  assign_public_ip  = false
  source_dest_check = true

  ssh_authorized_keys = var.ssh_public_key
  user_data           = local.user_data
  extended_metadata = {
    app_tier = "web"
  }

  # Boot volume
  boot_volume_size_in_gbs   = 100
  boot_volume_vpus_per_gb   = 20
  boot_volume_backup_policy = "silver"
  preserve_boot_volume      = false

  # Block volumes
  block_volumes = {
    "data" = {
      size_in_gbs     = 500
      vpus_per_gb     = 10
      backup_policy   = "bronze"
      attachment_type = "paravirtualized"
    }
    "logs" = {
      size_in_gbs     = 100
      vpus_per_gb     = 0
      attachment_type = "paravirtualized"
    }
  }

  # Cloud agent plugins
  cloud_agent_plugins = {
    monitoring             = "ENABLED"
    bastion                = "ENABLED"
    osms                   = "ENABLED"
    vulnerability_scanning = "ENABLED"
    custom_logs            = "ENABLED"
    block_volume_mgmt      = "DISABLED"
    management             = "DISABLED"
  }

  # Metadata options (IMDSv2 enforcement)
  metadata_options = {
    is_http_tokens_enabled = true
  }

  # NSG — created by this module, attached to instance VNIC
  create_nsg = true
  nsg_vcn_id = module.vcn.vcn_id
  nsg_name   = "${local.name}-nsg"

  # Egress: IPv4-only (VCN has no IPv6, so ::/0 would be rejected by OCI)
  nsg_egress_rules = {
    all_ipv4 = {
      protocol         = "all"
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      description      = "Allow all outbound IPv4 traffic"
    }
  }

  nsg_ingress_rules = {
    ssh = {
      protocol    = "6"
      source      = "10.0.0.0/16"
      source_type = "CIDR_BLOCK"
      description = "Allow SSH from within VCN"
      tcp_options = {
        destination_port_range = { min = 22, max = 22 }
      }
    }
    http = {
      protocol    = "6"
      source      = "10.0.0.0/16"
      source_type = "CIDR_BLOCK"
      description = "Allow HTTP from within VCN"
      tcp_options = {
        destination_port_range = { min = 80, max = 80 }
      }
    }
  }

  instance_state = "RUNNING"

  tags          = local.tags
  instance_tags = { "Role" = "web-server" }
}
