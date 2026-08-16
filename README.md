# OCI Compute Instance Terraform Module

Terraform module which creates Compute Instance resources on Oracle Cloud Infrastructure (OCI).

Designed to be familiar to users of the [terraform-aws-modules/ec2-instance/aws](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance) module: the same variable names where the concept is shared, the same file structure, with OCI resource names where the two clouds differ. See [docs/feature_parity.md](docs/feature_parity.md) for the full mapping.

## Usage

```hcl
module "instance" {
  source  = "terraform-oci-modules/compute-instance/oci"
  version = "~> 0.2"

  name           = "my-instance"
  compartment_id = var.compartment_id

  source_id  = var.image_id
  shape      = "VM.Standard.E4.Flex"
  shape_config = {
    ocpus         = 2
    memory_in_gbs = 16
  }

  subnet_id           = module.vcn.private_subnets[0]
  ssh_authorized_keys = file("~/.ssh/id_rsa.pub")

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

## Flex Shapes

OCI Flex shapes allow independent selection of OCPU count and memory - unlike AWS instance types
which are fixed bundles. Any shape ending in `.Flex` requires `shape_config`:

```hcl
shape      = "VM.Standard.E4.Flex"
shape_config = {
  ocpus         = 4
  memory_in_gbs = 32
}
```

Burstable CPU (equivalent to AWS `t` family `cpu_credits`) is configured via
`shape_config.baseline_ocpu_utilization`:

```hcl
shape_config = {
  ocpus                     = 1
  memory_in_gbs             = 8
  baseline_ocpu_utilization = "BASELINE_1_2"  # 50% baseline, bursts to 100%
}
```

## Availability Domains

OCI availability domains are referenced by number (`1`, `2`, or `3`). The module resolves
the number to the tenancy-specific AD name automatically:

```hcl
availability_domain = 1  # resolves to e.g. "abCD:US-ASHBURN-AD-1"
```

## Public IP

OCI supports two kinds of public IPs:

- **Ephemeral** (lost on instance replacement): `assign_public_ip = true`
- **Reserved** (static, survives replacement): `create_reserved_public_ip = true`

Reserved IPs map to AWS Elastic IPs.

## Instance Principal (IAM)

To allow the instance to call OCI APIs without credentials (equivalent to an AWS IAM instance profile),
create a Dynamic Group and policy **outside this module** using the OCI Identity provider:

```hcl
resource "oci_identity_dynamic_group" "instance" {
  compartment_id = var.tenancy_id
  name           = "my-instance-dg"
  description    = "Instances that can call OCI APIs"
  matching_rule  = "Any {instance.id = '${module.instance.id}'}"
}

resource "oci_identity_policy" "instance" {
  compartment_id = var.compartment_id
  name           = "my-instance-policy"
  description    = "Allow instance to read objects"
  statements     = ["Allow dynamic-group my-instance-dg to read objects in compartment id ${var.compartment_id}"]
}
```

OCI Instance Principal is architecturally different from AWS IAM instance profiles - Dynamic Groups
and policies are tenant-level constructs managed separately from the compute instance.

## Tags

OCI supports two tag types, both mapped:

| Variable       | OCI tag type    |
| -------------- | --------------- |
| `tags`         | `freeform_tags` |
| `defined_tags` | `defined_tags`  |

Per-resource overrides follow the same pair: `instance_tags` / `instance_defined_tags`, plus
`nsg_tags` and `reserved_public_ip_tags`.

## Examples

- [simple](examples/simple) - Minimal instance with private networking
- [complete](examples/complete) - All features: flex shape, block volumes, NSG, boot volume backup, metadata options
- [flex-shape](examples/flex-shape) - Burstable OCPU modes (BASELINE_1_1, BASELINE_1_2, BASELINE_1_8)
- [block-volumes](examples/block-volumes) - Paravirtualized and iSCSI block volume attachments
- [reserved-ip](examples/reserved-ip) - Reserved (static) public IP creation and attachment
- [windows](examples/windows) - Windows Server instance with credential output
- [capacity-reservation](examples/capacity-reservation) - Launch into a pre-provisioned capacity reservation
- [ipv6](examples/ipv6) - Dual-stack instance with IPv6 address assignment
- [secondary-network-interface](examples/secondary-network-interface) - Attaching a secondary VNIC after launch


## Wrappers

- [wrappers](wrappers) - Terragrunt-style `for_each` wrapper for the root module

## Testing

Each example ships with a [`terraform test`](https://developer.hashicorp.com/terraform/language/tests) file that applies real OCI resources, asserts key outputs, then destroys on completion. See [docs/testing.md](docs/testing.md) for prerequisites, OCI auth setup, and how to run the tests.

## AWS to OCI feature parity

See [docs/feature_parity.md](docs/feature_parity.md) for the full comparison against
`terraform-aws-modules/ec2-instance/aws`: feature, variable and output mapping, what is not
applicable to OCI, and what is not yet implemented.

## Related Projects

### Official Oracle module

Oracle maintains official Terraform modules for OCI compute resources:
[oracle-terraform-modules/terraform-oci-compute-instance](https://github.com/oracle-terraform-modules/terraform-oci-compute-instance)

**When to use the official module:**
- You prefer OCI-native variable naming conventions
- You want a module maintained directly by Oracle

**When to use this module:**
- You are migrating from AWS and want the same variable names as `terraform-aws-modules/ec2-instance/aws`
- You want a consistent interface across AWS and OCI infrastructure

### Disclaimer

This is an independent community module and is **not affiliated with, endorsed by, or supported by Oracle Corporation**. Oracle Cloud Infrastructure (OCI) is a trademark of Oracle Corporation. This module uses the publicly available [OCI Terraform provider](https://registry.terraform.io/providers/oracle/oci/latest) under its Mozilla Public License 2.0.

## License

[Apache 2.0](LICENSE)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_oci"></a> [oci](#provider\_oci) | >= 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [oci_core_instance.ignore_image](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance) | resource |
| [oci_core_instance.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance) | resource |
| [oci_core_network_security_group.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group) | resource |
| [oci_core_network_security_group_security_rule.egress](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_network_security_group_security_rule.ingress](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_network_security_group_security_rule) | resource |
| [oci_core_public_ip.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip) | resource |
| [oci_core_vnic_attachment.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vnic_attachment) | resource |
| [oci_core_volume.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_volume) | resource |
| [oci_core_volume_attachment.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_volume_attachment) | resource |
| [oci_core_volume_backup_policy_assignment.block](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_volume_backup_policy_assignment) | resource |
| [oci_core_volume_backup_policy_assignment.boot](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_volume_backup_policy_assignment) | resource |
| [oci_core_instance_credentials.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_instance_credentials) | data source |
| [oci_core_private_ips.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_private_ips) | data source |
| [oci_core_vnic.secondary](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_vnic) | data source |
| [oci_core_vnic_attachments.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_vnic_attachments) | data source |
| [oci_core_volume_backup_policies.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_volume_backup_policies) | data source |
| [oci_identity_availability_domains.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_are_all_plugins_disabled"></a> [are\_all\_plugins\_disabled](#input\_are\_all\_plugins\_disabled) | Whether to disable all cloud agent plugins. When true, overrides individual plugin settings | `bool` | `false` | no |
| <a name="input_assign_ipv6ip"></a> [assign\_ipv6ip](#input\_assign\_ipv6ip) | Whether to auto-assign an IPv6 address from the subnet's IPv6 CIDR pool.<br/>Maps to ipv6\_addresses / ipv6\_address\_count in the AWS module.<br/>Requires the subnet (and VCN) to have IPv6 enabled. When true and<br/>ipv6address\_ipv6subnet\_cidr\_pair\_details is empty, OCI picks an address<br/>automatically from each IPv6-enabled subnet CIDR associated with the VNIC.<br/>When false (default), no IPv6 address is assigned. | `bool` | `false` | no |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether to assign an ephemeral public IP to the primary VNIC.<br/>Maps to associate\_public\_ip\_address in AWS.<br/>For a stable public IP, use create\_reserved\_public\_ip instead. | `bool` | `false` | no |
| <a name="input_availability_domain"></a> [availability\_domain](#input\_availability\_domain) | Availability domain number (1, 2, or 3) where the instance will be placed.<br/>The module resolves the number to the tenancy-specific AD name automatically.<br/>Maps to the AWS availability\_zone concept. | `number` | `1` | no |
| <a name="input_block_volumes"></a> [block\_volumes](#input\_block\_volumes) | Map of block volumes to create and attach to the instance. Maps to<br/>ebs\_block\_device in AWS. Each key becomes part of the volume display\_name.<br/><br/>Example:<br/>  block\_volumes = {<br/>    "data" = {<br/>      size\_in\_gbs     = 100<br/>      vpus\_per\_gb     = 10          # 0=low, 10=balanced, 20=high<br/>      backup\_policy   = "bronze"    # "gold"/"silver"/"bronze"/"disabled"<br/>      attachment\_type = "paravirtualized"  # or "iscsi"<br/>      kms\_key\_id      = null        # KMS key OCID, or null for OCI-managed<br/>      tags            = {}<br/>      defined\_tags    = {}<br/>    }<br/>  } | <pre>map(object({<br/>    size_in_gbs     = number<br/>    vpus_per_gb     = optional(number, 10)<br/>    backup_policy   = optional(string, "disabled")<br/>    attachment_type = optional(string, "paravirtualized")<br/>    kms_key_id      = optional(string)<br/>    tags            = optional(map(string), {})<br/>    defined_tags    = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_boot_volume"></a> [boot\_volume](#input\_boot\_volume) | Boot volume settings. Maps to root\_block\_device in AWS.<br/><br/>  size\_in\_gbs   - Size in GBs. When null, the image's minimum size is used.<br/>  vpus\_per\_gb   - Performance level in VPUs per GB:<br/>                    0   Lower Cost (low iops, good for dev/test)<br/>                    10  Balanced (general purpose)<br/>                    20  Higher Performance<br/>                    30+ Ultra High Performance (30-120, increments of 10)<br/>  kms\_key\_id    - KMS key OCID used to encrypt the volume. When null, OCI-managed<br/>                  encryption is used.<br/>  backup\_policy - OCI predefined backup policy: "gold" (daily, weekly, monthly and<br/>                  yearly), "silver" (daily and weekly), "bronze" (monthly and<br/>                  yearly), or "disabled".<br/>  preserve      - Keep the boot volume when the instance is terminated. Maps to<br/>                  root\_block\_device.delete\_on\_termination (inverted). | <pre>object({<br/>    size_in_gbs   = optional(number)<br/>    vpus_per_gb   = optional(number)<br/>    kms_key_id    = optional(string)<br/>    backup_policy = optional(string, "disabled")<br/>    preserve      = optional(bool, false)<br/>  })</pre> | `{}` | no |
| <a name="input_capacity_reservation_id"></a> [capacity\_reservation\_id](#input\_capacity\_reservation\_id) | OCID of a compute capacity reservation to launch this instance into.<br/>Maps to capacity\_reservation\_specification in the AWS module.<br/><br/>When set, OCI guarantees that the required compute capacity exists before<br/>the instance is launched. The instance shape and shape\_config must match<br/>the instance\_reservation\_configs defined on the reservation.<br/><br/>When null (default), the instance is launched without targeting a reservation. | `string` | `null` | no |
| <a name="input_cloud_agent_plugins"></a> [cloud\_agent\_plugins](#input\_cloud\_agent\_plugins) | Map of cloud agent plugin aliases to their desired state ("ENABLED" or "DISABLED").<br/>Aliases are normalized to OCI plugin names automatically.<br/><br/>Available aliases:<br/>  monitoring             → "Compute Instance Monitoring"<br/>  bastion                → "Bastion"<br/>  run\_command            → "Run Command"<br/>  osms                   → "OS Management Service Agent"<br/>  custom\_logs            → "Custom Logs Monitoring"<br/>  vulnerability\_scanning → "Vulnerability Scanning"<br/>  block\_volume\_mgmt      → "Block Volume Management"<br/>  management             → "Management Agent"<br/>  java\_management\_service→ "Java Management Service"<br/>  autonomous\_linux       → "Oracle Autonomous Linux"<br/><br/>You may also pass OCI plugin names directly (the full string). | `map(string)` | `{}` | no |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id) | The OCID of the compartment where all resources will be created | `string` | n/a | yes |
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created (master switch - affects all resources) | `bool` | `true` | no |
| <a name="input_create_nsg"></a> [create\_nsg](#input\_create\_nsg) | Whether to create a Network Security Group for this instance. Maps to create\_security\_group in AWS | `bool` | `false` | no |
| <a name="input_create_reserved_public_ip"></a> [create\_reserved\_public\_ip](#input\_create\_reserved\_public\_ip) | Whether to create a reserved (static) public IP and assign it to the instance.<br/>Maps to create\_eip in the AWS module. Use this for a stable outbound IP that<br/>survives instance replacement (unlike assign\_public\_ip which is ephemeral). | `bool` | `false` | no |
| <a name="input_dedicated_vm_host_id"></a> [dedicated\_vm\_host\_id](#input\_dedicated\_vm\_host\_id) | OCID of the dedicated VM host to place this instance on. Maps to AWS host\_id / dedicated host tenancy | `string` | `null` | no |
| <a name="input_defined_tags"></a> [defined\_tags](#input\_defined\_tags) | A map of defined tags (namespace.key = value) to add to all resources | `map(string)` | `{}` | no |
| <a name="input_extended_metadata"></a> [extended\_metadata](#input\_extended\_metadata) | OCI-specific key-value map merged into instance metadata. Use for custom key-value pairs beyond ssh\_authorized\_keys and user\_data | `map(string)` | `{}` | no |
| <a name="input_fault_domain"></a> [fault\_domain](#input\_fault\_domain) | The fault domain within the availability domain where the instance will be placed.<br/>OCI-native feature with no direct AWS equivalent.<br/>Valid values: "FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3".<br/>When null (default), OCI selects a fault domain automatically.<br/>Use this to spread instances across fault domains for higher resiliency. | `string` | `null` | no |
| <a name="input_hostname_label"></a> [hostname\_label](#input\_hostname\_label) | The hostname label for the instance in the subnet's DNS zone (e.g. "myserver" → "myserver.subnet.vcn.oraclevcn.com") | `string` | `null` | no |
| <a name="input_ignore_image_changes"></a> [ignore\_image\_changes](#input\_ignore\_image\_changes) | If true, Terraform will ignore changes to source\_details (image/boot\_volume).<br/>Maps to ignore\_ami\_changes in the AWS EC2 module. Useful when images are<br/>managed by patching pipelines and you don't want Terraform to replace the<br/>instance on every image update. | `bool` | `false` | no |
| <a name="input_instance_defined_tags"></a> [instance\_defined\_tags](#input\_instance\_defined\_tags) | Defined tags applied to the instance only (merged with defined\_tags) | `map(string)` | `{}` | no |
| <a name="input_instance_initiated_shutdown_behavior"></a> [instance\_initiated\_shutdown\_behavior](#input\_instance\_initiated\_shutdown\_behavior) | What happens when the OS initiates a shutdown. Maps to<br/>instance\_initiated\_shutdown\_behavior in AWS.<br/>"STOP"      → instance stops (can be restarted)<br/>"TERMINATE" → instance is permanently terminated<br/>null        → use OCI default (STOP) | `string` | `null` | no |
| <a name="input_instance_state"></a> [instance\_state](#input\_instance\_state) | Desired state of the instance: "RUNNING" (default) or "STOPPED" | `string` | `"RUNNING"` | no |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | Tags applied to the instance only (merged with var.tags) | `map(string)` | `{}` | no |
| <a name="input_ipv6address_ipv6subnet_cidr_pair_details"></a> [ipv6address\_ipv6subnet\_cidr\_pair\_details](#input\_ipv6address\_ipv6subnet\_cidr\_pair\_details) | List of specific IPv6 address + subnet CIDR pairs to assign to the primary VNIC.<br/>Maps to ipv6\_addresses in the AWS module.<br/>Each entry specifies the /64 subnet CIDR (ipv6subnet\_cidr) from which the<br/>address should come; ipv6address is optional - omit it to let OCI auto-select.<br/>Ignored when assign\_ipv6ip = false.<br/>Example: [{ ipv6subnet\_cidr = "2001:db8::/64", ipv6address = "2001:db8::10" }] | <pre>list(object({<br/>    ipv6subnet_cidr = string<br/>    ipv6address     = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_ipxe_script"></a> [ipxe\_script](#input\_ipxe\_script) | Custom iPXE script to run at instance boot. OCI-native feature with no direct AWS equivalent.<br/>Overrides the default iPXE boot script provided by OCI. Useful for custom network boot<br/>sequences or chainloading. Was present in the legacy OCI compute module.<br/>When null (default), the standard OCI iPXE boot process is used. | `string` | `null` | no |
| <a name="input_is_management_disabled"></a> [is\_management\_disabled](#input\_is\_management\_disabled) | Whether to disable the Management Agent plugin on this instance | `bool` | `false` | no |
| <a name="input_is_monitoring_disabled"></a> [is\_monitoring\_disabled](#input\_is\_monitoring\_disabled) | Whether to disable the Compute Instance Monitoring plugin. Maps to disabling detailed monitoring in AWS | `bool` | `false` | no |
| <a name="input_is_pv_encryption_in_transit_enabled"></a> [is\_pv\_encryption\_in\_transit\_enabled](#input\_is\_pv\_encryption\_in\_transit\_enabled) | Whether to enable in-transit encryption for data moving between the instance and<br/>its paravirtualized boot/block volumes. OCI-native feature with no direct AWS equivalent.<br/>When true, all paravirtualized volume I/O is encrypted end-to-end within the host.<br/>Defaults to true (secure by default). Only applies to paravirtualized attachments (not iSCSI). | `bool` | `true` | no |
| <a name="input_is_windows_instance"></a> [is\_windows\_instance](#input\_is\_windows\_instance) | Set to true when launching a Windows image. Enables fetching initial credentials<br/>via the oci\_core\_instance\_credentials data source. Maps to get\_password\_data in AWS.<br/>The credentials are exposed via the instance\_credentials output. | `bool` | `false` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Instance metadata service options. Maps to metadata\_options in AWS (IMDSv2).<br/><br/>is\_http\_tokens\_enabled - When true, enforces token-based (IMDSv2-style) metadata<br/>                         access, disabling legacy HTTP endpoint access.<br/>                         Defaults to true (secure by default). Set to false only<br/>                         when a workload requires legacy IMDS access. | <pre>object({<br/>    is_http_tokens_enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on all resources as identifier (display\_name) | `string` | `""` | no |
| <a name="input_nsg_egress_rules"></a> [nsg\_egress\_rules](#input\_nsg\_egress\_rules) | Map of egress rules to add to the created NSG. Defaults to allowing all<br/>IPv4 and IPv6 outbound traffic (same behavior as a new AWS security group).<br/><br/>destination\_type: "CIDR\_BLOCK", "NETWORK\_SECURITY\_GROUP", "SERVICE\_CIDR\_BLOCK" | <pre>map(object({<br/>    protocol         = string<br/>    destination      = string<br/>    destination_type = string<br/>    description      = optional(string)<br/>    tcp_options = optional(object({<br/>      destination_port_range = optional(object({ min = number, max = number }))<br/>    }))<br/>    udp_options = optional(object({<br/>      destination_port_range = optional(object({ min = number, max = number }))<br/>    }))<br/>    icmp_options = optional(object({<br/>      type = number<br/>      code = optional(number)<br/>    }))<br/>  }))</pre> | <pre>{<br/>  "allow_all_ipv4": {<br/>    "description": "Allow all outbound IPv4 traffic",<br/>    "destination": "0.0.0.0/0",<br/>    "destination_type": "CIDR_BLOCK",<br/>    "protocol": "all"<br/>  },<br/>  "allow_all_ipv6": {<br/>    "description": "Allow all outbound IPv6 traffic",<br/>    "destination": "::/0",<br/>    "destination_type": "CIDR_BLOCK",<br/>    "protocol": "all"<br/>  }<br/>}</pre> | no |
| <a name="input_nsg_ids"></a> [nsg\_ids](#input\_nsg\_ids) | List of existing Network Security Group OCIDs to attach to the primary VNIC.<br/>Maps to vpc\_security\_group\_ids in AWS.<br/>This is additive with any NSG created by create\_nsg = true. | `list(string)` | `[]` | no |
| <a name="input_nsg_ingress_rules"></a> [nsg\_ingress\_rules](#input\_nsg\_ingress\_rules) | Map of ingress rules to add to the created NSG. Maps to ingress rules in<br/>an AWS security group.<br/><br/>Example:<br/>  nsg\_ingress\_rules = {<br/>    ssh = {<br/>      protocol    = "6"          # TCP<br/>      source      = "0.0.0.0/0"<br/>      source\_type = "CIDR\_BLOCK"<br/>      description = "Allow SSH"<br/>      tcp\_options = {<br/>        destination\_port\_range = { min = 22, max = 22 }<br/>      }<br/>    }<br/>  }<br/><br/>protocol values: "6" = TCP, "17" = UDP, "1" = ICMP, "all" = all traffic<br/>source\_type:     "CIDR\_BLOCK", "NETWORK\_SECURITY\_GROUP", "SERVICE\_CIDR\_BLOCK" | <pre>map(object({<br/>    protocol    = string<br/>    source      = string<br/>    source_type = string<br/>    description = optional(string)<br/>    tcp_options = optional(object({<br/>      destination_port_range = optional(object({ min = number, max = number }))<br/>      source_port_range      = optional(object({ min = number, max = number }))<br/>    }))<br/>    udp_options = optional(object({<br/>      destination_port_range = optional(object({ min = number, max = number }))<br/>      source_port_range      = optional(object({ min = number, max = number }))<br/>    }))<br/>    icmp_options = optional(object({<br/>      type = number<br/>      code = optional(number)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_nsg_name"></a> [nsg\_name](#input\_nsg\_name) | Name for the created NSG. Defaults to "<name>-nsg" when null | `string` | `null` | no |
| <a name="input_nsg_tags"></a> [nsg\_tags](#input\_nsg\_tags) | Additional freeform tags to apply to the created NSG only | `map(string)` | `{}` | no |
| <a name="input_nsg_vcn_id"></a> [nsg\_vcn\_id](#input\_nsg\_vcn\_id) | The OCID of the VCN in which to create the NSG. Required when create\_nsg = true | `string` | `null` | no |
| <a name="input_preemptible_instance_config"></a> [preemptible\_instance\_config](#input\_preemptible\_instance\_config) | Configuration for preemptible (spot-equivalent) instances. Maps to<br/>instance\_market\_options in AWS. When null, the instance is on-demand.<br/><br/>OCI preemptible instances are terminated when capacity is needed; there is no<br/>price bidding - you pay a fixed lower price.<br/><br/>action                          - "TERMINATE" (default) or "STOP" (shape-dependent)<br/>preserve\_boot\_volume\_on\_termination - Whether to keep the boot volume on preemption | <pre>object({<br/>    action                              = string<br/>    preserve_boot_volume_on_termination = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_private_ip"></a> [private\_ip](#input\_private\_ip) | Private IP address to assign to the primary VNIC. When null, OCI auto-assigns an IP from the subnet CIDR | `string` | `null` | no |
| <a name="input_reserved_public_ip_tags"></a> [reserved\_public\_ip\_tags](#input\_reserved\_public\_ip\_tags) | Additional freeform tags to apply to the reserved public IP resource only | `map(string)` | `{}` | no |
| <a name="input_secondary_network_interface"></a> [secondary\_network\_interface](#input\_secondary\_network\_interface) | Map of secondary VNICs to attach to the instance after launch. Maps to<br/>secondary\_network\_interface in the AWS module. Each key becomes part of<br/>the VNIC attachment's display\_name.<br/><br/>nic\_index selects the physical network card (0 by default; only relevant<br/>on bare metal shapes with multiple physical NICs). There is no OCI<br/>equivalent of AWS's device\_index - the OS assigns VNIC device names.<br/><br/>This variable only attaches the VNIC at the infrastructure level; it does<br/>not configure the guest OS. OCI does not run DHCP on secondary VNICs, so<br/>the interface appears inside the instance (e.g. as ens5) with no IP<br/>assigned until you configure it, typically with a static address matching<br/>private\_ip. On Oracle Linux images, run `sudo oci-network-config configure`<br/>(from the preinstalled oci-utils package) to do this automatically; on<br/>other distros, configure the interface manually (netplan, nmcli, etc.).<br/><br/>Example:<br/>  secondary\_network\_interface = {<br/>    "eth1" = {<br/>      subnet\_id = "ocid1.subnet.oc1..."<br/>    }<br/>  } | <pre>map(object({<br/>    subnet_id                 = string<br/>    nic_index                 = optional(number, 0)<br/>    private_ip                = optional(string)<br/>    assign_public_ip          = optional(bool, false)<br/>    assign_ipv6ip             = optional(bool, false)<br/>    assign_private_dns_record = optional(bool, true)<br/>    hostname_label            = optional(string)<br/>    skip_source_dest_check    = optional(bool, false)<br/>    nsg_ids                   = optional(list(string), [])<br/>    display_name              = optional(string)<br/>    tags                      = optional(map(string), {})<br/>    defined_tags              = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_shape"></a> [shape](#input\_shape) | The shape of the instance, e.g. "VM.Standard.E4.Flex" or "VM.Standard3.Flex".<br/>Maps to the AWS instance\_type concept.<br/><br/>Shapes ending in ".Flex" require shape\_config to specify OCPU and memory.<br/>Fixed shapes (e.g. "VM.Standard.E3.Flex") use OCI-defined resource sizes. | `string` | `"VM.Standard.E4.Flex"` | no |
| <a name="input_shape_config"></a> [shape\_config](#input\_shape\_config) | Shape configuration for Flex shapes. Ignored for fixed shapes.<br/><br/>ocpus                     - Number of OCPUs (e.g. 1, 2, 4, 8). Maps to cpu\_options.core\_count.<br/>memory\_in\_gbs             - Memory in GB (e.g. 16, 32, 64).<br/>baseline\_ocpu\_utilization - Burstable CPU mode. Maps to cpu\_credits in AWS.<br/>                            "BASELINE\_1\_1"  → 100% baseline (Standard)<br/>                            "BASELINE\_1\_2"  → 50%  baseline (Burstable)<br/>                            "BASELINE\_1\_8"  → 12.5% baseline (Burstable) | <pre>object({<br/>    ocpus                     = optional(number)<br/>    memory_in_gbs             = optional(number)<br/>    baseline_ocpu_utilization = optional(string)<br/>  })</pre> | `{}` | no |
| <a name="input_source_dest_check"></a> [source\_dest\_check](#input\_source\_dest\_check) | Whether to enable source/destination checking on the primary VNIC.<br/>Maps directly to the AWS source\_dest\_check flag - true (default) enables the check.<br/>Set to false when the instance acts as a router, NAT, or firewall. | `bool` | `true` | no |
| <a name="input_source_id"></a> [source\_id](#input\_source\_id) | The OCID of the image or boot volume to use as the instance source.<br/>Maps to the AWS AMI ID concept.<br/><br/>When source\_type = "image"       → provide an image OCID<br/>When source\_type = "boot\_volume" → provide a boot volume OCID | `string` | `null` | no |
| <a name="input_source_type"></a> [source\_type](#input\_source\_type) | Type of the instance source. Either "image" (default) or "boot\_volume" | `string` | `"image"` | no |
| <a name="input_ssh_authorized_keys"></a> [ssh\_authorized\_keys](#input\_ssh\_authorized\_keys) | One or more SSH public keys to inject into the instance via cloud-init metadata.<br/>Pass the full public key string(s) (newline-separated for multiple keys).<br/>Maps to the AWS key\_name concept, but OCI injects the key material directly<br/>rather than using named key pairs. | `string` | `null` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | The OCID of the subnet to launch the instance into. Maps to subnet\_id in AWS | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Timeout configuration for instance create/update/delete operations (e.g. "30m", "1h") | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Base64-encoded cloud-init user data script to run on first boot.<br/>Same concept as AWS user\_data. Use base64encode() to encode your script. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_availability_domain"></a> [availability\_domain](#output\_availability\_domain) | The availability domain name where the instance was placed |
| <a name="output_block_volume_attachments"></a> [block\_volume\_attachments](#output\_block\_volume\_attachments) | Map of block volume name to volume attachment attributes |
| <a name="output_block_volumes"></a> [block\_volumes](#output\_block\_volumes) | Map of block volume name to attributes: {id, availability\_domain, size\_in\_gbs} |
| <a name="output_boot_volume_id"></a> [boot\_volume\_id](#output\_boot\_volume\_id) | The OCID of the boot volume |
| <a name="output_hostname_label"></a> [hostname\_label](#output\_hostname\_label) | The hostname label of the instance in the subnet DNS zone |
| <a name="output_id"></a> [id](#output\_id) | The OCID of the instance |
| <a name="output_image_id"></a> [image\_id](#output\_image\_id) | The OCID of the source image used to launch the instance |
| <a name="output_instance_all_attributes"></a> [instance\_all\_attributes](#output\_instance\_all\_attributes) | Attributes of the created instance, excluding 3 deprecated top-level fields (hostname\_label, image, subnet\_id) whose non-deprecated equivalents are included under create\_vnic\_details/source\_details |
| <a name="output_instance_credentials"></a> [instance\_credentials](#output\_instance\_credentials) | Initial Windows credentials fetched from OCI (username + password). Only populated when is\_windows\_instance = true |
| <a name="output_name"></a> [name](#output\_name) | The name specified as argument to this module |
| <a name="output_nsg_all_attributes"></a> [nsg\_all\_attributes](#output\_nsg\_all\_attributes) | All attributes of the created NSG (full object, auto-updating) |
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | The OCID of the Network Security Group created by this module. Null when create\_nsg = false |
| <a name="output_primary_vnic_id"></a> [primary\_vnic\_id](#output\_primary\_vnic\_id) | The OCID of the primary VNIC attachment |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | The private IP address of the primary VNIC |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | The public IP address of the instance (ephemeral or reserved). Null when no public IP is assigned |
| <a name="output_reserved_public_ip"></a> [reserved\_public\_ip](#output\_reserved\_public\_ip) | All attributes of the reserved public IP resource. Null when create\_reserved\_public\_ip = false |
| <a name="output_reserved_public_ip_address"></a> [reserved\_public\_ip\_address](#output\_reserved\_public\_ip\_address) | The reserved public IP address string. Null when not created |
| <a name="output_resolved_availability_domain"></a> [resolved\_availability\_domain](#output\_resolved\_availability\_domain) | The resolved availability domain name (e.g. "abCD:US-ASHBURN-AD-1") |
| <a name="output_secondary_network_interfaces"></a> [secondary\_network\_interfaces](#output\_secondary\_network\_interfaces) | Map of secondary network interface name to resolved attributes: {vnic\_id, nic\_index, private\_ip, public\_ip, mac\_address} |
| <a name="output_secondary_vnic_attachments"></a> [secondary\_vnic\_attachments](#output\_secondary\_vnic\_attachments) | Map of secondary network interface name to VNIC attachment attributes (full object, auto-updating) |
| <a name="output_shape"></a> [shape](#output\_shape) | The shape of the instance |
| <a name="output_state"></a> [state](#output\_state) | The current state of the instance (RUNNING, STOPPED, TERMINATED, etc.) |
<!-- END_TF_DOCS -->
