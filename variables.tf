################################################################################
# Core / Control
################################################################################

variable "create" {
  description = "Controls if resources should be created (master switch - affects all resources)"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to be used on all resources as identifier (display_name)"
  type        = string
  default     = ""
}

variable "compartment_id" {
  description = "The OCID of the compartment where all resources will be created"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.[a-z0-9]+\\.", var.compartment_id))
    error_message = "compartment_id must be a valid OCI OCID starting with ocid1.compartment or ocid1.tenancy."
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "defined_tags" {
  description = "A map of defined tags (namespace.key = value) to add to all resources"
  type        = map(string)
  default     = {}
  nullable    = false
}

################################################################################
# Image / Source  (maps to AMI)
################################################################################

variable "source_id" {
  description = <<-EOT
    The OCID of the image or boot volume to use as the instance source.
    Maps to the AWS AMI ID concept.

    When source_type = "image"       → provide an image OCID
    When source_type = "boot_volume" → provide a boot volume OCID
  EOT
  type        = string
  default     = null
}

variable "source_type" {
  description = "Type of the instance source. Either \"image\" (default) or \"boot_volume\""
  type        = string
  default     = "image"

  validation {
    condition     = contains(["image", "boot_volume"], var.source_type)
    error_message = "source_type must be \"image\" or \"boot_volume\"."
  }
}

variable "ignore_image_changes" {
  description = <<-EOT
    If true, Terraform will ignore changes to source_details (image/boot_volume).
    Maps to ignore_ami_changes in the AWS EC2 module. Useful when images are
    managed by patching pipelines and you don't want Terraform to replace the
    instance on every image update.
  EOT
  type        = bool
  default     = false
}

################################################################################
# Shape / Instance Type  (maps to instance_type)
################################################################################

variable "shape" {
  description = <<-EOT
    The shape of the instance, e.g. "VM.Standard.E4.Flex" or "VM.Standard3.Flex".
    Maps to the AWS instance_type concept.

    Shapes ending in ".Flex" require shape_config to specify OCPU and memory.
    Fixed shapes (e.g. "VM.Standard.E3.Flex") use OCI-defined resource sizes.
  EOT
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "shape_config" {
  description = <<-EOT
    Shape configuration for Flex shapes. Ignored for fixed shapes.

    ocpus                     - Number of OCPUs (e.g. 1, 2, 4, 8). Maps to cpu_options.core_count.
    memory_in_gbs             - Memory in GB (e.g. 16, 32, 64).
    baseline_ocpu_utilization - Burstable CPU mode. Maps to cpu_credits in AWS.
                                "BASELINE_1_1"  → 100% baseline (Standard)
                                "BASELINE_1_2"  → 50%  baseline (Burstable)
                                "BASELINE_1_8"  → 12.5% baseline (Burstable)
  EOT
  type = object({
    ocpus                     = optional(number)
    memory_in_gbs             = optional(number)
    baseline_ocpu_utilization = optional(string)
  })
  default = {}

  validation {
    condition = (
      try(var.shape_config.baseline_ocpu_utilization, null) == null
      || try(contains(
        ["BASELINE_1_1", "BASELINE_1_2", "BASELINE_1_8"],
        var.shape_config.baseline_ocpu_utilization
      ), false)
    )
    error_message = "shape_config.baseline_ocpu_utilization must be \"BASELINE_1_1\", \"BASELINE_1_2\", or \"BASELINE_1_8\"."
  }
  nullable = false
}

################################################################################
# Placement
################################################################################

variable "availability_domain" {
  description = <<-EOT
    Availability domain number (1, 2, or 3) where the instance will be placed.
    The module resolves the number to the tenancy-specific AD name automatically.
    Maps to the AWS availability_zone concept.
  EOT
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 3], var.availability_domain)
    error_message = "availability_domain must be 1, 2, or 3."
  }
}

variable "dedicated_vm_host_id" {
  description = "OCID of the dedicated VM host to place this instance on. Maps to AWS host_id / dedicated host tenancy"
  type        = string
  default     = null
}

variable "capacity_reservation_id" {
  description = <<-EOT
    OCID of a compute capacity reservation to launch this instance into.
    Maps to capacity_reservation_specification in the AWS module.

    When set, OCI guarantees that the required compute capacity exists before
    the instance is launched. The instance shape and shape_config must match
    the instance_reservation_configs defined on the reservation.

    When null (default), the instance is launched without targeting a reservation.
  EOT
  type        = string
  default     = null
}

variable "fault_domain" {
  description = <<-EOT
    The fault domain within the availability domain where the instance will be placed.
    OCI-native feature with no direct AWS equivalent.
    Valid values: "FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3".
    When null (default), OCI selects a fault domain automatically.
    Use this to spread instances across fault domains for higher resiliency.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.fault_domain == null ? true : contains(["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"], var.fault_domain)
    error_message = "fault_domain must be one of: FAULT-DOMAIN-1, FAULT-DOMAIN-2, FAULT-DOMAIN-3."
  }
}

variable "is_pv_encryption_in_transit_enabled" {
  description = <<-EOT
    Whether to enable in-transit encryption for data moving between the instance and
    its paravirtualized boot/block volumes. OCI-native feature with no direct AWS equivalent.
    When true, all paravirtualized volume I/O is encrypted end-to-end within the host.
    Defaults to true (secure by default). Only applies to paravirtualized attachments (not iSCSI).
  EOT
  type        = bool
  default     = true
}

variable "ipxe_script" {
  description = <<-EOT
    Custom iPXE script to run at instance boot. OCI-native feature with no direct AWS equivalent.
    Overrides the default iPXE boot script provided by OCI. Useful for custom network boot
    sequences or chainloading. Was present in the legacy OCI compute module.
    When null (default), the standard OCI iPXE boot process is used.
  EOT
  type        = string
  default     = null
}

################################################################################
# Networking
################################################################################

variable "subnet_id" {
  description = "The OCID of the subnet to launch the instance into. Maps to subnet_id in AWS"
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = <<-EOT
    Whether to assign an ephemeral public IP to the primary VNIC.
    Maps to associate_public_ip_address in AWS.
    For a stable public IP, use create_reserved_public_ip instead.
  EOT
  type        = bool
  default     = false
}

variable "private_ip" {
  description = "Private IP address to assign to the primary VNIC. When null, OCI auto-assigns an IP from the subnet CIDR"
  type        = string
  default     = null
}

variable "hostname_label" {
  description = "The hostname label for the instance in the subnet's DNS zone (e.g. \"myserver\" → \"myserver.subnet.vcn.oraclevcn.com\")"
  type        = string
  default     = null
}

variable "source_dest_check" {
  description = <<-EOT
    Whether to enable source/destination checking on the primary VNIC.
    Maps directly to the AWS source_dest_check flag - true (default) enables the check.
    Set to false when the instance acts as a router, NAT, or firewall.
  EOT
  type        = bool
  default     = true
}

variable "nsg_ids" {
  description = <<-EOT
    List of existing Network Security Group OCIDs to attach to the primary VNIC.
    Maps to vpc_security_group_ids in AWS.
    This is additive with any NSG created by create_nsg = true.
  EOT
  type        = list(string)
  default     = []
  nullable    = false
}

variable "assign_ipv6ip" {
  description = <<-EOT
    Whether to auto-assign an IPv6 address from the subnet's IPv6 CIDR pool.
    Maps to ipv6_addresses / ipv6_address_count in the AWS module.
    Requires the subnet (and VCN) to have IPv6 enabled. When true and
    ipv6address_ipv6subnet_cidr_pair_details is empty, OCI picks an address
    automatically from each IPv6-enabled subnet CIDR associated with the VNIC.
    When false (default), no IPv6 address is assigned.
  EOT
  type        = bool
  default     = false
}

variable "ipv6address_ipv6subnet_cidr_pair_details" {
  description = <<-EOT
    List of specific IPv6 address + subnet CIDR pairs to assign to the primary VNIC.
    Maps to ipv6_addresses in the AWS module.
    Each entry specifies the /64 subnet CIDR (ipv6subnet_cidr) from which the
    address should come; ipv6address is optional - omit it to let OCI auto-select.
    Ignored when assign_ipv6ip = false.
    Example: [{ ipv6subnet_cidr = "2001:db8::/64", ipv6address = "2001:db8::10" }]
  EOT
  type = list(object({
    ipv6subnet_cidr = string
    ipv6address     = optional(string)
  }))
  default  = []
  nullable = false
}

variable "secondary_network_interface" {
  description = <<-EOT
    Map of secondary VNICs to attach to the instance after launch. Maps to
    secondary_network_interface in the AWS module. Each key becomes part of
    the VNIC attachment's display_name.

    nic_index selects the physical network card (0 by default; only relevant
    on bare metal shapes with multiple physical NICs). There is no OCI
    equivalent of AWS's device_index - the OS assigns VNIC device names.

    This variable only attaches the VNIC at the infrastructure level; it does
    not configure the guest OS. OCI does not run DHCP on secondary VNICs, so
    the interface appears inside the instance (e.g. as ens5) with no IP
    assigned until you configure it, typically with a static address matching
    private_ip. On Oracle Linux images, run `sudo oci-network-config configure`
    (from the preinstalled oci-utils package) to do this automatically; on
    other distros, configure the interface manually (netplan, nmcli, etc.).

    create_reserved_public_ip attaches a stable (RESERVED) public IP to this
    secondary VNIC's private IP, independent of assign_public_ip (which is
    ephemeral and tied to the VNIC's own lifecycle). The AWS module has no
    equivalent: create_eip only covers the primary interface there, with no
    variable for a persistent Elastic IP on a secondary one.

    Example:
      secondary_network_interface = {
        "eth1" = {
          subnet_id = "ocid1.subnet.oc1..."
        }
      }
  EOT
  type = map(object({
    subnet_id                 = string
    nic_index                 = optional(number, 0)
    private_ip                = optional(string)
    assign_public_ip          = optional(bool, false)
    assign_ipv6ip             = optional(bool, false)
    assign_private_dns_record = optional(bool, true)
    hostname_label            = optional(string)
    skip_source_dest_check    = optional(bool, false)
    nsg_ids                   = optional(list(string), [])
    display_name              = optional(string)
    create_reserved_public_ip = optional(bool, false)
    reserved_public_ip_tags   = optional(map(string), {})
    tags                      = optional(map(string), {})
    defined_tags              = optional(map(string), {})
  }))
  default  = {}
  nullable = false
}

################################################################################
# SSH / OS
################################################################################

variable "ssh_authorized_keys" {
  description = <<-EOT
    One or more SSH public keys to inject into the instance via cloud-init metadata.
    Pass the full public key string(s) (newline-separated for multiple keys).
    Maps to the AWS key_name concept, but OCI injects the key material directly
    rather than using named key pairs.
  EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "user_data" {
  description = <<-EOT
    Base64-encoded cloud-init user data script to run on first boot.
    Same concept as AWS user_data. Use base64encode() to encode your script.
  EOT
  type        = string
  default     = null
}

variable "extended_metadata" {
  description = "OCI-specific key-value map merged into instance metadata. Use for custom key-value pairs beyond ssh_authorized_keys and user_data"
  type        = map(string)
  default     = {}
  nullable    = false
}

################################################################################
# Boot Volume  (maps to root_block_device)
################################################################################

variable "boot_volume" {
  description = <<-EOT
    Boot volume settings. Maps to root_block_device in AWS.

      size_in_gbs   - Size in GBs. When null, the image's minimum size is used.
      vpus_per_gb   - Performance level in VPUs per GB:
                        0   Lower Cost (low iops, good for dev/test)
                        10  Balanced (general purpose)
                        20  Higher Performance
                        30+ Ultra High Performance (30-120, increments of 10)
      kms_key_id    - KMS key OCID used to encrypt the volume. When null, OCI-managed
                      encryption is used.
      backup_policy - OCI predefined backup policy: "gold" (daily, weekly, monthly and
                      yearly), "silver" (daily and weekly), "bronze" (monthly and
                      yearly), or "disabled".
      preserve      - Keep the boot volume when the instance is terminated. Maps to
                      root_block_device.delete_on_termination (inverted).
  EOT
  type = object({
    size_in_gbs   = optional(number)
    vpus_per_gb   = optional(number)
    kms_key_id    = optional(string)
    backup_policy = optional(string, "disabled")
    preserve      = optional(bool, false)
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["gold", "silver", "bronze", "disabled"], var.boot_volume.backup_policy)
    error_message = "boot_volume.backup_policy must be \"gold\", \"silver\", \"bronze\", or \"disabled\"."
  }
}

################################################################################
# Block Volumes  (maps to ebs_block_device)
################################################################################

variable "block_volumes" {
  description = <<-EOT
    Map of block volumes to create and attach to the instance. Maps to
    ebs_block_device in AWS. Each key becomes part of the volume display_name.

    Example:
      block_volumes = {
        "data" = {
          size_in_gbs     = 100
          vpus_per_gb     = 10          # 0=low, 10=balanced, 20=high
          backup_policy   = "bronze"    # "gold"/"silver"/"bronze"/"disabled"
          attachment_type = "paravirtualized"  # or "iscsi"
          kms_key_id      = null        # KMS key OCID, or null for OCI-managed
          tags            = {}
          defined_tags    = {}
        }
      }
  EOT
  type = map(object({
    size_in_gbs     = number
    vpus_per_gb     = optional(number, 10)
    backup_policy   = optional(string, "disabled")
    attachment_type = optional(string, "paravirtualized")
    kms_key_id      = optional(string)
    tags            = optional(map(string), {})
    defined_tags    = optional(map(string), {})
  }))
  default  = {}
  nullable = false
}

################################################################################
# Cloud Agent / Monitoring  (maps to monitoring + CloudWatch agent)
################################################################################

variable "is_monitoring_disabled" {
  description = "Whether to disable the Compute Instance Monitoring plugin. Maps to disabling detailed monitoring in AWS"
  type        = bool
  default     = false
}

variable "is_management_disabled" {
  description = "Whether to disable the Management Agent plugin on this instance"
  type        = bool
  default     = false
}

variable "are_all_plugins_disabled" {
  description = "Whether to disable all cloud agent plugins. When true, overrides individual plugin settings"
  type        = bool
  default     = false
}

variable "cloud_agent_plugins" {
  description = <<-EOT
    Map of cloud agent plugin aliases to their desired state ("ENABLED" or "DISABLED").
    Aliases are normalized to OCI plugin names automatically.

    Available aliases:
      monitoring             → "Compute Instance Monitoring"
      bastion                → "Bastion"
      run_command            → "Run Command"
      osms                   → "OS Management Service Agent"
      custom_logs            → "Custom Logs Monitoring"
      vulnerability_scanning → "Vulnerability Scanning"
      block_volume_mgmt      → "Block Volume Management"
      management             → "Management Agent"
      java_management_service→ "Java Management Service"
      autonomous_linux       → "Oracle Autonomous Linux"

    You may also pass OCI plugin names directly (the full string).
  EOT
  type        = map(string)
  default     = {}
  nullable    = false
}

################################################################################
# Metadata Options  (maps to metadata_options / IMDSv2)
################################################################################

variable "metadata_options" {
  description = <<-EOT
    Instance metadata service options. Maps to metadata_options in AWS (IMDSv2).

    is_http_tokens_enabled - When true, enforces token-based (IMDSv2-style) metadata
                             access, disabling legacy HTTP endpoint access.
                             Defaults to true (secure by default). Set to false only
                             when a workload requires legacy IMDS access.
  EOT
  type = object({
    is_http_tokens_enabled = optional(bool, true)
  })
  default  = {}
  nullable = false
}

################################################################################
# NSG Creation  (maps to create_security_group / security_group_*)
################################################################################

variable "create_nsg" {
  description = "Whether to create a Network Security Group for this instance. Maps to create_security_group in AWS"
  type        = bool
  default     = false
}

variable "nsg_vcn_id" {
  description = "The OCID of the VCN in which to create the NSG. Required when create_nsg = true"
  type        = string
  default     = null
}

variable "nsg_name" {
  description = "Name for the created NSG. Defaults to \"<name>-nsg\" when null"
  type        = string
  default     = null
}

variable "nsg_tags" {
  description = "Additional freeform tags to apply to the created NSG only"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "nsg_ingress_rules" {
  description = <<-EOT
    Map of ingress rules to add to the created NSG. Maps to ingress rules in
    an AWS security group.

    Example:
      nsg_ingress_rules = {
        ssh = {
          protocol    = "6"          # TCP
          source      = "0.0.0.0/0"
          source_type = "CIDR_BLOCK"
          description = "Allow SSH"
          tcp_options = {
            destination_port_range = { min = 22, max = 22 }
          }
        }
      }

    protocol values: "6" = TCP, "17" = UDP, "1" = ICMP, "all" = all traffic
    source_type:     "CIDR_BLOCK", "NETWORK_SECURITY_GROUP", "SERVICE_CIDR_BLOCK"
  EOT
  type = map(object({
    protocol    = string
    source      = string
    source_type = string
    description = optional(string)
    tcp_options = optional(object({
      destination_port_range = optional(object({ min = number, max = number }))
      source_port_range      = optional(object({ min = number, max = number }))
    }))
    udp_options = optional(object({
      destination_port_range = optional(object({ min = number, max = number }))
      source_port_range      = optional(object({ min = number, max = number }))
    }))
    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
  default  = {}
  nullable = false
}

variable "nsg_egress_rules" {
  description = <<-EOT
    Map of egress rules to add to the created NSG. Defaults to allowing all
    IPv4 and IPv6 outbound traffic (same behavior as a new AWS security group).

    destination_type: "CIDR_BLOCK", "NETWORK_SECURITY_GROUP", "SERVICE_CIDR_BLOCK"
  EOT
  type = map(object({
    protocol         = string
    destination      = string
    destination_type = string
    description      = optional(string)
    tcp_options = optional(object({
      destination_port_range = optional(object({ min = number, max = number }))
    }))
    udp_options = optional(object({
      destination_port_range = optional(object({ min = number, max = number }))
    }))
    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
  default = {
    allow_all_ipv4 = {
      protocol         = "all"
      destination      = "0.0.0.0/0"
      destination_type = "CIDR_BLOCK"
      description      = "Allow all outbound IPv4 traffic"
    }
    allow_all_ipv6 = {
      protocol         = "all"
      destination      = "::/0"
      destination_type = "CIDR_BLOCK"
      description      = "Allow all outbound IPv6 traffic"
    }
  }
  nullable = false
}

################################################################################
# Reserved Public IP  (maps to Elastic IP / create_eip)
################################################################################

variable "create_reserved_public_ip" {
  description = <<-EOT
    Whether to create a reserved (static) public IP and assign it to the instance.
    Maps to create_eip in the AWS module. Use this for a stable outbound IP that
    survives instance replacement (unlike assign_public_ip which is ephemeral).
  EOT
  type        = bool
  default     = false
}

variable "reserved_public_ip_tags" {
  description = "Additional freeform tags to apply to the reserved public IP resource only"
  type        = map(string)
  default     = {}
  nullable    = false
}

################################################################################
# Preemptible Instance  (maps to create_spot_instance)
################################################################################

variable "preemptible_instance_config" {
  description = <<-EOT
    Configuration for preemptible (spot-equivalent) instances. Maps to
    instance_market_options in AWS. When null, the instance is on-demand.

    OCI preemptible instances are terminated when capacity is needed; there is no
    price bidding - you pay a fixed lower price.

    action                          - "TERMINATE" (default) or "STOP" (shape-dependent)
    preserve_boot_volume_on_termination - Whether to keep the boot volume on preemption
  EOT
  type = object({
    action                              = string
    preserve_boot_volume_on_termination = optional(bool, false)
  })
  default = null

  validation {
    condition = (
      var.preemptible_instance_config == null
      || try(contains(["TERMINATE", "STOP"], var.preemptible_instance_config.action), false)
    )
    error_message = "preemptible_instance_config.action must be \"TERMINATE\" or \"STOP\"."
  }
}

################################################################################
# Windows
################################################################################

variable "is_windows_instance" {
  description = <<-EOT
    Set to true when launching a Windows image. Enables fetching initial credentials
    via the oci_core_instance_credentials data source. Maps to get_password_data in AWS.
    The credentials are exposed via the instance_credentials output.
  EOT
  type        = bool
  default     = false
}

################################################################################
# Instance Lifecycle
################################################################################

variable "instance_state" {
  description = "Desired state of the instance: \"RUNNING\" (default) or \"STOPPED\""
  type        = string
  default     = "RUNNING"

  validation {
    condition     = contains(["RUNNING", "STOPPED"], var.instance_state)
    error_message = "instance_state must be \"RUNNING\" or \"STOPPED\"."
  }
}

variable "instance_initiated_shutdown_behavior" {
  description = <<-EOT
    What happens when the OS initiates a shutdown. Maps to
    instance_initiated_shutdown_behavior in AWS.
    "STOP"      → instance stops (can be restarted)
    "TERMINATE" → instance is permanently terminated
    null        → use OCI default (STOP)
  EOT
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Timeout configuration for instance create/update/delete operations (e.g. \"30m\", \"1h\")"
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

################################################################################
# Per-resource Tags
################################################################################

variable "instance_tags" {
  description = "Tags applied to the instance only (merged with var.tags)"
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "instance_defined_tags" {
  description = "Defined tags applied to the instance only (merged with defined_tags)"
  type        = map(string)
  default     = {}
  nullable    = false
}
