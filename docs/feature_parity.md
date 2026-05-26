# Feature Parity: OCI Compute Instance vs AWS EC2 Instance

Comparison between this module (`terraform-oci-modules/compute-instance/oci`) and the
reference AWS module (`terraform-aws-modules/ec2-instance/aws`).

The goal is not 1:1 mapping — OCI and AWS have fundamentally different primitives — but to
make the interface feel familiar to users coming from the AWS module, while being idiomatic OCI.

**Legend:**
- ✅ Implemented
- ⬜ Not yet implemented — OCI provider supports this; module doesn't expose it yet
- N/A Not applicable to this cloud (architectural difference, not a gap)
- OCI-only No AWS equivalent — intentional addition

---

## 1. Core / Control

| Feature                      | AWS      | OCI              | Status                      |
| ---------------------------- | -------- | ---------------- | --------------------------- |
| Create toggle                | `create` | `create`         | ✅                           |
| Resource name                | `name`   | `name`           | ✅                           |
| Compartment scoping          | —        | `compartment_id` | OCI-only                    |
| Per-resource region override | `region` | —                | N/A (provider-level in OCI) |

---

## 2. Image / Source

| Feature                 | AWS                  | OCI                                          | Status                      |
| ----------------------- | -------------------- | -------------------------------------------- | --------------------------- |
| Image ID                | `ami`                | `source_id`                                  | ✅                           |
| Image via SSM parameter | `ami_ssm_parameter`  | —                                            | N/A (no SSM service in OCI) |
| Ignore image changes    | `ignore_ami_changes` | `ignore_image_changes`                       | ✅                           |
| Source type selection   | —                    | `source_type` (`"image"` \| `"boot_volume"`) | OCI-only (see note below)   |

> **Source type**: OCI supports launching an instance directly from an existing boot volume (e.g.
> for fast cloning or disaster recovery). AWS has no equivalent — AMIs encapsulate the snapshot.

---

## 3. Shape / Instance Type

| Feature               | AWS                                        | OCI                                                                                           | Status                                        |
| --------------------- | ------------------------------------------ | --------------------------------------------------------------------------------------------- | --------------------------------------------- |
| Instance type / shape | `instance_type`                            | `shape`                                                                                       | ✅                                             |
| OCPU / core count     | `cpu_options.core_count`                   | `shape_config.ocpus`                                                                          | ✅                                             |
| Memory (independent)  | —                                          | `shape_config.memory_in_gbs`                                                                  | OCI-only (see note below)                     |
| Burstable CPU credits | `cpu_credits` (`"standard"`/`"unlimited"`) | `shape_config.baseline_ocpu_utilization` (`"BASELINE_1_1"`/`"BASELINE_1_2"`/`"BASELINE_1_8"`) | ✅                                             |
| Threads per core      | `cpu_options.threads_per_core`             | —                                                                                             | N/A                                           |
| AMD SEV-SNP           | `cpu_options.amd_sev_snp`                  | —                                                                                             | N/A                                           |
| EBS-optimized flag    | `ebs_optimized`                            | —                                                                                             | N/A (OCI storage is always network-optimized) |
| Nitro Enclaves        | `enclave_options_enabled`                  | —                                                                                             | N/A (AWS-specific security feature)           |

> **Flex shapes**: OCI shapes ending in `.Flex` allow independent selection of OCPU count and
> memory. AWS instance types are fixed bundles. This is why `shape_config` exists as a separate
> variable rather than encoding everything in the shape name.

---

## 4. Placement

| Feature                          | AWS                                               | OCI                                                    | Status                                                     |
| -------------------------------- | ------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------- |
| Availability zone / domain       | `availability_zone` (string, e.g. `"us-east-1a"`) | `availability_domain` (integer: 1, 2, or 3)            | ✅                                                          |
| AD name resolution               | —                                                 | Auto-resolved from `oci_identity_availability_domains` | OCI-only                                                   |
| Dedicated host                   | `host_id`                                         | `dedicated_vm_host_id`                                 | ✅                                                          |
| Dedicated host resource group    | `host_resource_group_arn`                         | —                                                      | N/A                                                        |
| Capacity reservation             | `capacity_reservation_specification`              | `capacity_reservation_id`                              | ✅                                                          |
| Fault domain                     | —                                                 | `fault_domain`                                         | OCI-only ✅                                                 |
| Placement group                  | `placement_group` / `placement_partition_number`  | —                                                      | N/A (OCI Cluster Networks are out of scope)                |
| Tenancy (default/dedicated/host) | `tenancy`                                         | —                                                      | N/A (OCI tenancy is the root org, not a placement concept) |

> **Capacity reservations**: OCI compute capacity reservations are created via
> `oci_core_compute_capacity_reservation`. Instances target a reservation by setting
> `capacity_reservation_id`. The instance shape and `shape_config` must match the
> reservation's `instance_reservation_configs` exactly.
>
> **Fault domain**: OCI ADs are subdivided into fault domains (FD-1, FD-2, FD-3) for
> physical isolation within the same AD. The `fault_domain` string attribute on
> `oci_core_instance` controls placement. AWS has no direct equivalent at this granularity.

---

## 5. Networking

| Feature                     | AWS                                                             | OCI                                                                                   | Status                                                    |
| --------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| Subnet                      | `subnet_id`                                                     | `subnet_id`                                                                           | ✅                                                         |
| Ephemeral public IP         | `associate_public_ip_address`                                   | `assign_public_ip`                                                                    | ✅                                                         |
| Specific private IP         | `private_ip`                                                    | `private_ip`                                                                          | ✅                                                         |
| DNS hostname label          | —                                                               | `hostname_label`                                                                      | OCI-only                                                  |
| Source/destination check    | `source_dest_check` (default true)                              | `source_dest_check` (default true)                                                    | ✅                                                         |
| Attach existing NSGs/SGs    | `vpc_security_group_ids`                                        | `nsg_ids`                                                                             | ✅                                                         |
| Secondary private IPs       | `secondary_private_ips`                                         | —                                                                                     | N/A (OCI supports secondary VNICs but not in this module) |
| Network interface at launch | `network_interface`                                             | —                                                                                     | N/A (OCI VNIC attachments work differently)               |
| IPv6 address assignment     | `enable_primary_ipv6` / `ipv6_address_count` / `ipv6_addresses` | `assign_ipv6ip` / `ipv6address_ipv6subnet_cidr_pair_details` in `create_vnic_details` | ✅ (see note below)                                        |

> **Hostname label**: OCI injects a DNS label directly on the VNIC at launch time
> (e.g. `"myhost"` → `myhost.subnet.vcn.oraclevcn.com`). AWS private DNS is managed
> at the VPC level via `private_dns_name_options`.
>
> **IPv6**: OCI supports IPv6 address assignment at the VNIC level via `assign_ipv6ip`
> (auto-assign from the subnet's IPv6 CIDR pool; default `false`) and
> `ipv6address_ipv6subnet_cidr_pair_details` (pin a specific address per subnet CIDR).
> Requires the VCN and subnet to have IPv6 enabled. Note the two-step workflow: on
> the first apply OCI assigns the VCN a /56 prefix and the subnet gets its /64; IPv6
> addresses can then be assigned on the same or a subsequent apply.

---

## 6. SSH / OS Access

| Feature                              | AWS                           | OCI                                           | Status                                        |
| ------------------------------------ | ----------------------------- | --------------------------------------------- | --------------------------------------------- |
| SSH key                              | `key_name` (key pair name)    | `ssh_authorized_keys` (raw public key string) | ✅ (see note below)                            |
| User data                            | `user_data`                   | `user_data` (always base64)                   | ✅                                             |
| User data base64 variant             | `user_data_base64`            | —                                             | N/A (OCI `user_data` accepts base64 directly) |
| Replace instance on user data change | `user_data_replace_on_change` | —                                             | N/A                                           |
| Additional metadata                  | —                             | `extended_metadata`                           | OCI-only                                      |

> **SSH key mechanism**: AWS references a named key pair stored in EC2. OCI injects the raw
> public key material directly into the instance via metadata (`ssh_authorized_keys`). No
> pre-registration of key pairs is needed.

---

## 7. Boot Volume

| Feature                    | AWS                                                      | OCI                                                               | Status                                                                                                   |
| -------------------------- | -------------------------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Boot volume size           | `root_block_device.size`                                 | `boot_volume_size_in_gbs`                                         | ✅                                                                                                        |
| Boot volume encryption key | `root_block_device.kms_key_id`                           | `boot_volume_encryption_key_id`                                   | ✅                                                                                                        |
| Delete on termination      | `root_block_device.delete_on_termination` (default true) | `preserve_boot_volume` (default false, inverted)                  | ✅                                                                                                        |
| Performance (IOPS)         | `root_block_device.iops`                                 | `boot_volume_vpus_per_gb` (0/10/20/30-120)                        | ✅ (see note below)                                                                                       |
| Throughput                 | `root_block_device.throughput`                           | —                                                                 | N/A (VPU model covers this implicitly)                                                                   |
| Volume type                | `root_block_device.type`                                 | —                                                                 | N/A (OCI has one volume type)                                                                            |
| Volume tags                | `root_block_device.tags`                                 | —                                                                 | N/A (OCI boot volumes cannot be tagged at launch time; use `boot_volume_id` output to manage externally) |
| Predefined backup policy   | —                                                        | `boot_volume_backup_policy` (`gold`/`silver`/`bronze`/`disabled`) | OCI-only                                                                                                 |

> **VPUs vs IOPS**: OCI uses a VPU (Volume Performance Units) model instead of explicit IOPS.
> `0` = low cost, `10` = balanced (default), `20` = high performance, `30-120` = ultra high.
> There is no throughput knob separate from VPUs.

---

## 8. Block Volumes

| Feature                      | AWS                                  | OCI                                                    | Status                                                         |
| ---------------------------- | ------------------------------------ | ------------------------------------------------------ | -------------------------------------------------------------- |
| Additional volumes (map)     | `ebs_volumes`                        | `block_volumes`                                        | ✅                                                              |
| Volume size                  | `.size`                              | `.size_in_gbs`                                         | ✅                                                              |
| Encryption key               | `.kms_key_id`                        | `.encryption_key_id`                                   | ✅                                                              |
| Performance                  | `.iops` / `.throughput`              | `.vpus_per_gb`                                         | ✅ (VPU model, see §7)                                          |
| Attachment type              | —                                    | `.attachment_type` (`"paravirtualized"` \| `"iscsi"`)  | OCI-only                                                       |
| Per-volume backup policy     | —                                    | `.backup_policy` (`gold`/`silver`/`bronze`/`disabled`) | OCI-only                                                       |
| Per-volume tags              | `.tags`                              | `.freeform_tags` / `.defined_tags`                     | ✅                                                              |
| Volume type                  | `.type` (gp3, io1, etc.)             | —                                                      | N/A (OCI has one volume type)                                  |
| Final snapshot on destroy    | `.final_snapshot`                    | —                                                      | N/A                                                            |
| Multi-attach                 | `.multi_attach_enabled`              | —                                                      | N/A                                                            |
| Outpost ARN                  | `.outpost_arn`                       | —                                                      | N/A                                                            |
| Create from snapshot         | `.snapshot_id`                       | —                                                      | N/A (use `source_id` + `source_type = "boot_volume"` for boot) |
| Force detach / skip destroy  | `.force_detach` / `.skip_destroy`    | —                                                      | N/A                                                            |
| Stop before detach           | `.stop_instance_before_detaching`    | —                                                      | N/A                                                            |
| Volume tags (instance-level) | `volume_tags` / `enable_volume_tags` | —                                                      | N/A (OCI tags are per-volume in `block_volumes`)               |

---

## 9. Cloud Agent / Monitoring

| Feature                     | AWS          | OCI                                             | Status                    |
| --------------------------- | ------------ | ----------------------------------------------- | ------------------------- |
| Detailed monitoring         | `monitoring` | `is_monitoring_disabled` (inverted)             | ✅                         |
| Management agent            | —            | `is_management_disabled`                        | OCI-only                  |
| Disable all plugins         | —            | `are_all_plugins_disabled`                      | OCI-only                  |
| Fine-grained plugin control | —            | `cloud_agent_plugins` (map of 10 named plugins) | OCI-only (see note below) |

> **Cloud agent plugins**: OCI instances run a Cloud Agent with individually controllable plugins:
> Compute Instance Monitoring, Bastion, Run Command, OS Management, Custom Logs, Vulnerability
> Scanning, Block Volume Management, Management Agent, Java Management Service, Oracle Autonomous
> Linux. Each can be `"ENABLED"` or `"DISABLED"` independently. AWS CloudWatch agent is configured
> at the OS level, not the instance API.

---

## 10. Metadata Options (IMDSv2)

| Feature                         | AWS                                            | OCI                                                | Status |
| ------------------------------- | ---------------------------------------------- | -------------------------------------------------- | ------ |
| Require session tokens (IMDSv2) | `metadata_options.http_tokens` (`"required"`)  | `metadata_options.is_http_tokens_enabled` (`true`) | ✅      |
| HTTP endpoint toggle            | `metadata_options.http_endpoint`               | —                                                  | N/A    |
| IPv6 metadata endpoint          | `metadata_options.http_protocol_ipv6`          | —                                                  | N/A    |
| Hop limit                       | `metadata_options.http_put_response_hop_limit` | —                                                  | N/A    |
| Instance metadata tags          | `metadata_options.instance_metadata_tags`      | —                                                  | N/A    |

---

## 11. Network Security Group / Security Group

| Feature         | AWS                                    | OCI                                                      | Status                                    |
| --------------- | -------------------------------------- | -------------------------------------------------------- | ----------------------------------------- |
| Create SG/NSG   | `create_security_group` (default true) | `create_nsg` (default false)                             | ✅ (see note below)                        |
| SG/NSG name     | `security_group_name`                  | `nsg_name`                                               | ✅                                         |
| VPC/VCN scoping | `security_group_vpc_id`                | `nsg_vcn_id` (required when `create_nsg = true`)         | ✅                                         |
| SG/NSG tags     | `security_group_tags`                  | `nsg_tags`                                               | ✅                                         |
| Ingress rules   | `security_group_ingress_rules`         | `nsg_ingress_rules`                                      | ✅ (see note below)                        |
| Egress rules    | `security_group_egress_rules`          | `nsg_egress_rules` (default: allow all 0.0.0.0/0 + ::/0) | ✅                                         |
| Name prefix     | `security_group_use_name_prefix`       | —                                                        | N/A                                       |
| Description     | `security_group_description`           | —                                                        | N/A (NSG has no description field in OCI) |

> **Default create behavior**: AWS creates a security group by default (`create_security_group = true`).
> OCI defaults to `create_nsg = false` because OCI VCNs already have security lists at the subnet
> level; an NSG is additive and optional.
>
> **Rule schema**: AWS uses `cidr_ipv4`, `from_port`, `to_port`, `ip_protocol`. OCI uses numeric
> protocol codes (`"6"` = TCP, `"17"` = UDP, `"1"` = ICMP, `"all"`) with separate `tcp_options`,
> `udp_options`, and `icmp_options` blocks.

---

## 12. Reserved Public IP / Elastic IP

| Feature                 | AWS          | OCI                         | Status |
| ----------------------- | ------------ | --------------------------- | ------ |
| Create static public IP | `create_eip` | `create_reserved_public_ip` | ✅      |
| Static IP tags          | `eip_tags`   | `reserved_public_ip_tags`   | ✅      |
| Domain / scope          | `eip_domain` | —                           | N/A    |

> **Reserved vs Ephemeral**: OCI distinguishes between ephemeral public IPs (assigned at launch,
> lost on termination) and reserved public IPs (persistent, can be reassigned). `assign_public_ip`
> creates an ephemeral IP; `create_reserved_public_ip` creates a persistent one. AWS EIPs are
> always persistent.

---

## 13. IAM / Instance Principal

| Feature                 | AWS                                          | OCI | Status |
| ----------------------- | -------------------------------------------- | --- | ------ |
| Create IAM construct    | `create_iam_instance_profile`                | —   | N/A    |
| Attach existing profile | `iam_instance_profile`                       | —   | N/A    |
| Role path / name prefix | `iam_role_path` / `iam_role_use_name_prefix` | —   | N/A    |
| Permissions boundary    | `iam_role_permissions_boundary`              | —   | N/A    |
| Role tags               | `iam_role_tags`                              | —   | N/A    |

> **Why this entire section is N/A**: In AWS, the IAM Role is *attached to the instance* via an
> Instance Profile — so the module must create and wire it up at launch time. In OCI, Instance
> Principal auth works the opposite way: a Dynamic Group defines a *rule that matches instances*
> (e.g. all instances in a given compartment), and an IAM Policy grants that group permissions.
> The instance itself has nothing to configure — it is automatically a member of any Dynamic Group
> whose rule matches it. Dynamic Groups and Policies are tenancy-level administrative constructs
> managed outside the scope of an instance module.

---

## 14. Preemptible Instance / Spot

| Feature                             | AWS                                    | OCI                                                               | Status                                                      |
| ----------------------------------- | -------------------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------------- |
| Enable preemptible / spot           | `create_spot_instance`                 | `preemptible_instance_config != null`                             | ✅                                                           |
| Interruption behavior               | `spot_instance_interruption_behavior`  | `preemptible_instance_config.action` (`"TERMINATE"` \| `"STOP"`)  | ✅                                                           |
| Preserve boot volume on termination | —                                      | `preemptible_instance_config.preserve_boot_volume_on_termination` | OCI-only                                                    |
| Price bidding                       | `spot_price`                           | —                                                                 | N/A (OCI preemptible instances are fixed-price, no bidding) |
| Launch group                        | `spot_launch_group`                    | —                                                                 | N/A                                                         |
| Spot type (one-time/persistent)     | `spot_type`                            | —                                                                 | N/A                                                         |
| Wait for fulfillment                | `spot_wait_for_fulfillment`            | —                                                                 | N/A                                                         |
| Valid from / until                  | `spot_valid_from` / `spot_valid_until` | —                                                                 | N/A                                                         |
| Market options override             | `instance_market_options`              | —                                                                 | N/A                                                         |

> **Preemptible vs Spot**: OCI preemptible instances are reclaimed when Oracle needs capacity.
> There is no bidding market — you pay a fixed lower price. The `action` on reclamation is either
> `"TERMINATE"` (instance is deleted) or `"STOP"` (instance is stopped, shape-dependent).

---

## 15. Windows

| Feature                   | AWS                        | OCI                          | Status             |
| ------------------------- | -------------------------- | ---------------------------- | ------------------ |
| Fetch Windows credentials | `get_password_data` (bool) | `is_windows_instance` (bool) | ✅ (see note below) |
| Hibernation               | `hibernation`              | —                            | N/A                |

> **Credential retrieval**: AWS `get_password_data = true` returns a base64-encoded encrypted
> password blob that must be decrypted with the private key. OCI `is_windows_instance = true`
> triggers an `oci_core_instance_credentials` data source lookup that returns plaintext
> `{username, password}` directly via the OCI API (marked `sensitive`).

---

## 16. Instance Lifecycle

| Feature                | AWS                                                             | OCI                                                             | Status                                         |
| ---------------------- | --------------------------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------- |
| Shutdown behavior      | `instance_initiated_shutdown_behavior` (`"stop"`/`"terminate"`) | `instance_initiated_shutdown_behavior` (`"STOP"`/`"TERMINATE"`) | ✅                                              |
| Desired power state    | —                                                               | `instance_state` (`"RUNNING"` \| `"STOPPED"`)                   | OCI-only                                       |
| Termination protection | `disable_api_termination`                                       | —                                                               | N/A                                            |
| Stop protection        | `disable_api_stop`                                              | —                                                               | N/A                                            |
| Maintenance options    | `maintenance_options`                                           | —                                                               | N/A (OCI handles live migration automatically) |
| Launch template        | `launch_template`                                               | —                                                               | N/A                                            |
| Timeouts               | `timeouts`                                                      | `timeouts`                                                      | ✅                                              |

> **`instance_state`**: OCI lets Terraform declaratively manage whether the instance is running
> or stopped. This maps to nothing in AWS — stopping and starting is done out-of-band.

---

## 17. Tags

| Feature                        | AWS                                  | OCI                                       | Status                              |
| ------------------------------ | ------------------------------------ | ----------------------------------------- | ----------------------------------- |
| Resource tags                  | `tags`                               | `tags`                                    | ✅ Identical                         |
| Defined tags (namespace)       | —                                    | `defined_tags`                            | OCI-only                            |
| Instance-specific tags         | `instance_tags`                      | `instance_tags` / `instance_defined_tags` | ✅ Identical                         |
| Volume tags (instance-level)   | `volume_tags` / `enable_volume_tags` | —                                         | N/A (per-volume in `block_volumes`) |
| Inherited provider tags output | `tags_all` output                    | —                                         | N/A                                 |

---

## 18. Wrappers

| Wrapper             | AWS         | OCI         | Status |
| ------------------- | ----------- | ----------- | ------ |
| Root module wrapper | `wrappers/` | `wrappers/` | ✅      |

---

## Variables — Matched

| AWS                                          | OCI                                        | Notes                                   |
| -------------------------------------------- | ------------------------------------------ | --------------------------------------- |
| `create`                                     | `create`                                   | Identical                               |
| `name`                                       | `name`                                     | Identical                               |
| `ami`                                        | `source_id`                                | Image OCID                              |
| `ignore_ami_changes`                         | `ignore_image_changes`                     | Same behavior                           |
| `instance_type`                              | `shape`                                    | Shape name                              |
| `cpu_options.core_count`                     | `shape_config.ocpus`                       | OCPU count                              |
| `cpu_credits`                                | `shape_config.baseline_ocpu_utilization`   | Burstable CPU mode                      |
| `availability_zone`                          | `availability_domain`                      | AWS: string. OCI: integer 1/2/3         |
| `host_id`                                    | `dedicated_vm_host_id`                     | Dedicated host placement                |
| `capacity_reservation_specification`         | `capacity_reservation_id`                  | Capacity reservation OCID               |
| `subnet_id`                                  | `subnet_id`                                | Identical                               |
| `associate_public_ip_address`                | `assign_public_ip`                         | Ephemeral public IP                     |
| `enable_primary_ipv6` / `ipv6_address_count` | `assign_ipv6ip`                            | Auto-assign IPv6 from subnet pool       |
| `ipv6_addresses`                             | `ipv6address_ipv6subnet_cidr_pair_details` | Pin specific IPv6 addresses             |
| `private_ip`                                 | `private_ip`                               | Identical                               |
| `source_dest_check`                          | `source_dest_check`                        | Identical                               |
| `vpc_security_group_ids`                     | `nsg_ids`                                  | Attach existing NSG OCIDs               |
| `key_name`                                   | `ssh_authorized_keys`                      | AWS: key pair name. OCI: raw key string |
| `user_data`                                  | `user_data`                                | Both base64                             |
| `monitoring`                                 | `is_monitoring_disabled`                   | Inverted                                |
| `metadata_options.http_tokens`               | `metadata_options.is_http_tokens_enabled`  | IMDSv2 enforcement                      |
| `get_password_data`                          | `is_windows_instance`                      | Windows credential retrieval            |
| `instance_initiated_shutdown_behavior`       | `instance_initiated_shutdown_behavior`     | Case differs                            |
| `timeouts`                                   | `timeouts`                                 | Identical structure                     |
| `tags`                                       | `tags`                                     | Identical                               |
| `instance_tags`                              | `instance_tags`                            | Identical                               |
| `root_block_device.size`                     | `boot_volume_size_in_gbs`                  | Boot volume size                        |
| `root_block_device.kms_key_id`               | `boot_volume_encryption_key_id`            | KMS encryption                          |
| `root_block_device.delete_on_termination`    | `preserve_boot_volume`                     | Inverted                                |
| `root_block_device.iops`                     | `boot_volume_vpus_per_gb`                  | Performance (VPU model)                 |
| `ebs_volumes`                                | `block_volumes`                            | Additional volumes map                  |
| `ebs_volumes[*].kms_key_id`                  | `block_volumes[*].encryption_key_id`       | Per-volume encryption                   |
| `ebs_volumes[*].size`                        | `block_volumes[*].size_in_gbs`             | Per-volume size                         |
| `create_security_group`                      | `create_nsg`                               | Create network security group           |
| `security_group_name`                        | `nsg_name`                                 | NSG name                                |
| `security_group_vpc_id`                      | `nsg_vcn_id`                               | VCN scoping                             |
| `security_group_tags`                        | `nsg_tags`                                 | NSG tags                                |
| `security_group_ingress_rules`               | `nsg_ingress_rules`                        | Ingress rules (different schema)        |
| `security_group_egress_rules`                | `nsg_egress_rules`                         | Egress rules                            |
| `create_eip`                                 | `create_reserved_public_ip`                | Static public IP                        |
| `eip_tags`                                   | `reserved_public_ip_tags`                  | Static IP tags                          |
| `create_spot_instance`                       | `preemptible_instance_config != null`      | Preemptible/spot mode                   |
| `spot_instance_interruption_behavior`        | `preemptible_instance_config.action`       | Reclamation behavior                    |

---

## Variables — not yet implemented (OCI equivalent exists)

These AWS module variables have a supported OCI equivalent in the provider but are not yet
exposed by this module. They are the implementation backlog for AWS feature parity.

| AWS Variable         | OCI Equivalent       | Notes                                                                                                                                                                              |
| -------------------- | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ipv6_address_count` | No direct equivalent | OCI only supports binary auto-assign (`assign_ipv6ip`) or explicit pairs (`ipv6address_ipv6subnet_cidr_pair_details`). There is no "assign N IPv6 addresses" concept in OCI VNICs. |

---

## Variables — AWS only (no OCI equivalent)

| AWS Variable                                                                                                                                                                                                               | Reason not in OCI                                                                  |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `region`                                                                                                                                                                                                                   | Provider-level in OCI; no per-resource override                                    |
| `ami_ssm_parameter`                                                                                                                                                                                                        | No SSM service in OCI                                                              |
| `disable_api_termination` / `disable_api_stop`                                                                                                                                                                             | No instance protection in OCI                                                      |
| `ebs_optimized`                                                                                                                                                                                                            | OCI storage is always network-optimized                                            |
| `enclave_options_enabled`                                                                                                                                                                                                  | Nitro Enclaves is AWS-specific                                                     |
| `ephemeral_block_device`                                                                                                                                                                                                   | OCI has no instance store                                                          |
| `hibernation`                                                                                                                                                                                                              | Not supported in OCI                                                               |
| `host_resource_group_arn`                                                                                                                                                                                                  | AWS-specific dedicated host groups                                                 |
| `iam_instance_profile` / `create_iam_instance_profile` / `iam_role_name` / `iam_role_description` / `iam_role_policies` / `iam_role_use_name_prefix` / `iam_role_path` / `iam_role_permissions_boundary` / `iam_role_tags` | Dynamic Groups are not attached to instances — no module variable needed (see §13) |
| `launch_template`                                                                                                                                                                                                          | No launch templates in OCI                                                         |
| `maintenance_options`                                                                                                                                                                                                      | OCI handles live migration automatically                                           |
| `network_interface`                                                                                                                                                                                                        | OCI VNIC attachment works differently                                              |
| `placement_group` / `placement_partition_number`                                                                                                                                                                           | OCI Cluster Networks are out of scope                                              |
| `private_dns_name_options`                                                                                                                                                                                                 | OCI uses `hostname_label`                                                          |
| `secondary_private_ips`                                                                                                                                                                                                    | Secondary VNICs are out of scope                                                   |
| `tenancy`                                                                                                                                                                                                                  | Not a placement concept in OCI                                                     |
| `user_data_base64` / `user_data_replace_on_change`                                                                                                                                                                         | OCI `user_data` is always base64                                                   |
| `volume_tags` / `enable_volume_tags`                                                                                                                                                                                       | OCI tags are per-volume in `block_volumes`                                         |
| `spot_price` / `spot_type` / `spot_launch_group` / `spot_wait_for_fulfillment` / `spot_valid_from` / `spot_valid_until` / `instance_market_options`                                                                        | No spot market or bidding in OCI                                                   |
| `ebs_volumes.final_snapshot` / `.multi_attach_enabled` / `.outpost_arn` / `.snapshot_id` / `.throughput` / `.volume_initialization_rate` / `.force_detach` / `.skip_destroy` / `.stop_instance_before_detaching`           | AWS EBS-specific features                                                          |
| `eip_domain`                                                                                                                                                                                                               | No EIP domain concept in OCI                                                       |
| `security_group_use_name_prefix` / `security_group_description`                                                                                                                                                            | NSG has no description in OCI                                                      |

---

## Variables — OCI only (no AWS equivalent)

| OCI Variable                             | What it does                                                              |
| ---------------------------------------- | ------------------------------------------------------------------------- |
| `compartment_id`                         | Required OCI compartment scoping — no AWS concept                         |
| `source_type`                            | `"image"` or `"boot_volume"` — boot volume as instance source             |
| `shape_config.memory_in_gbs`             | Independent memory selection on Flex shapes                               |
| `boot_volume_vpus_per_gb`                | VPU-based performance tiers (0/10/20/30-120)                              |
| `boot_volume_backup_policy`              | Predefined backup policy (gold/silver/bronze/disabled)                    |
| `preserve_boot_volume`                   | Keep boot volume on instance termination                                  |
| `hostname_label`                         | DNS label in the subnet zone                                              |
| `is_management_disabled`                 | Disable OCI Management Agent plugin                                       |
| `are_all_plugins_disabled`               | Bulk-disable all cloud agent plugins                                      |
| `cloud_agent_plugins`                    | Fine-grained per-plugin enable/disable (10 plugins)                       |
| `extended_metadata`                      | OCI-specific additional metadata key-value map                            |
| `instance_state`                         | Declarative `"RUNNING"` / `"STOPPED"` desired state                       |
| `defined_tags` / `instance_defined_tags` | OCI tag namespace system                                                  |
| `block_volumes[*].attachment_type`       | `"paravirtualized"` or `"iscsi"`                                          |
| `block_volumes[*].backup_policy`         | Per-volume predefined backup policy                                       |
| `nsg_vcn_id`                             | NSGs are VCN-scoped; required when `create_nsg = true`                    |
| `fault_domain`                           | Fault domain placement within the AD (`"FAULT-DOMAIN-1"` / `"2"` / `"3"`) |
| `is_pv_encryption_in_transit_enabled`    | In-transit encryption for paravirtualized boot/block volume I/O           |
| `ipxe_script`                            | Custom iPXE boot script; overrides OCI default network boot sequence      |

### OCI-only — not yet implemented

These OCI provider attributes have no AWS equivalent and are not yet exposed by the module.

| OCI Provider Attribute | What it does |
| ---------------------- | ------------ |
_No OCI-native features remain unimplemented._

---

## Outputs — Matched

| AWS                            | OCI                        | Notes                                                        |
| ------------------------------ | -------------------------- | ------------------------------------------------------------ |
| `id`                           | `id`                       | Instance OCID                                                |
| `instance_state`               | `state`                    | Current power state                                          |
| `public_ip`                    | `public_ip`                | Covers ephemeral and reserved                                |
| `private_ip`                   | `private_ip`               | Primary private IP                                           |
| `primary_network_interface_id` | `primary_vnic_id`          | Primary NIC / VNIC OCID                                      |
| `ami`                          | `image_id`                 | Source image used                                            |
| `availability_zone`            | `availability_domain`      | Placement zone / domain                                      |
| `password_data`                | `instance_credentials`     | AWS: encrypted blob. OCI: `{username, password}` (sensitive) |
| `ebs_volumes`                  | `block_volumes`            | Map of attached volumes                                      |
| `ebs_block_device`             | `block_volume_attachments` | Volume attachment details                                    |
| `security_group_id`            | `nsg_id`                   | Created SG/NSG identifier                                    |

---

## Outputs — AWS only

| AWS Output                                                                         | Reason not in OCI                                                           |
| ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `arn`                                                                              | OCI uses OCIDs; covered by `id`                                             |
| `capacity_reservation_specification`                                               | OCI uses a simple OCID; accessible via `instance_all_attributes`            |
| `outpost_arn`                                                                      | AWS Outposts-specific                                                       |
| `private_dns` / `public_dns`                                                       | OCI DNS resolved via `hostname_label`; not surfaced as output               |
| `ipv6_addresses`                                                                   | Not surfaced as a dedicated output; access via `instance_all_attributes`    |
| `tags_all`                                                                         | OCI has no inherited provider-default tags                                  |
| `spot_bid_status` / `spot_request_state` / `spot_instance_id`                      | No spot market in OCI                                                       |
| `root_block_device` / `ephemeral_block_device`                                     | Not exposed as structured output in OCI                                     |
| `iam_role_name` / `iam_role_arn` / `iam_role_unique_id` / `iam_instance_profile_*` | N/A — Dynamic Groups are not attached to instances; no module output needed |
| `security_group_arn`                                                               | NSGs have no ARN in OCI                                                     |

---

## Outputs — OCI only

| OCI Output                                          | What it exposes                                 |
| --------------------------------------------------- | ----------------------------------------------- |
| `shape`                                             | OCI shape used                                  |
| `hostname_label`                                    | DNS label in the subnet zone                    |
| `boot_volume_id`                                    | Boot volume OCID                                |
| `instance_all_attributes`                           | Full `oci_core_instance` object (auto-updating) |
| `nsg_all_attributes`                                | Full NSG object (auto-updating)                 |
| `reserved_public_ip` / `reserved_public_ip_address` | Reserved IP object and address string           |
| `name`                                              | Echoes the `name` input (useful for wrappers)   |
| `resolved_availability_domain`                      | Full AD name after integer resolution           |

---

## Examples

### AWS examples

| Example           | What it covers                                                                                                                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `complete`        | Multiple module calls: basic instance, network interface, metadata options, t2/t3 unlimited (burstable), spot instance, `for_each` (multiple instances), `ignore_ami_changes`, disabled module |
| `session-manager` | SSH-less access via AWS SSM Session Manager — IAM role with `AmazonSSMManagedInstanceCore`, intra subnet (no IGW), no key pair                                                                 |

### OCI examples

| Example                | What it covers                                                                                                                                                                                  |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `simple`               | Minimal instance: E4.Flex 1 OCPU/8 GB, private subnet via NAT, no public IP                                                                                                                     |
| `complete`             | All features: flex shape (4 OCPU/32 GB), boot volume encryption + backup, block volumes, NSG with ingress rules, reserved public IP, dynamic group + IAM policy, user data, cloud agent plugins |
| `flex-shape`           | Three instances demonstrating `BASELINE_1_1`, `BASELINE_1_2`, and `BASELINE_1_8` burstable OCPU modes                                                                                           |
| `block-volumes`        | Paravirtualized, iSCSI, and archive block volumes with different backup policies                                                                                                                |
| `reserved-ip`          | Reserved (static) public IP — creates a new reserved IP and attaches it to an instance (`create_reserved_public_ip = true`)                                                                     |
| `windows`              | Windows Server instance with `assign_public_ip = true`, `is_windows_instance = true`, `instance_credentials` output                                                                             |
| `capacity-reservation` | Compute capacity reservation + instance targeting it — shape must match `instance_reservation_configs`                                                                                          |
| `ipv6`                 | Dual-stack instance (public IPv4 + auto-assigned IPv6) — VCN with `enable_ipv6 = true`, instance with `assign_ipv6ip = true`                                                                    |

### Example gap analysis

#### OCI missing vs AWS

| AWS Example / Scenario                       | OCI Status      | Notes                                                                               |
| -------------------------------------------- | --------------- | ----------------------------------------------------------------------------------- |
| `session-manager` — SSH-less access          | Not implemented | OCI equivalent: Bastion service + dynamic group. Potential future `bastion` example |
| `ec2_multiple` — `for_each` across instances | Not implemented | The `wrappers/` module covers this pattern; a dedicated example could showcase it   |
| Network interface attachment at launch       | N/A             | OCI VNIC attachments work differently; secondary VNICs are a separate resource      |
| Spot price bidding options                   | N/A             | OCI preemptible instances have no price bidding                                     |

#### AWS missing vs OCI

| OCI Example / Scenario                      | Notes                                                                                                                      |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `simple` — minimal standalone example       | AWS `complete` is the starting point; no dedicated minimal example                                                         |
| `flex-shape` — independent OCPU + memory    | No AWS concept; instance types are fixed bundles                                                                           |
| `block-volumes` — dedicated storage example | AWS covers EBS inline in `complete`; OCI warrants standalone due to attachment type differences (paravirtualized vs iSCSI) |
| `reserved-ip` — dedicated static IP example | AWS covers EIP inline in `complete`; OCI warrants standalone due to VNIC lookup chain complexity                           |
| `windows` — dedicated Windows example       | AWS includes Windows inline in `complete`; OCI warrants standalone due to public subnet topology requirement               |

---

## Summary

**Good parity:** core instance (image/source, shape, placement, networking, tags, shutdown behavior,
timeouts), block volumes, NSG/security group, public IP (EIP/reserved IP), spot/preemptible,
Windows credentials, user data, metadata options (IMDSv2).

**True AWS-only (confirmed N/A):** instance store, Nitro Enclaves, launch templates, placement
groups, spot price bidding, secondary private IPs, termination/stop protection, maintenance
options, EBS-specific volume features (snapshots, multi-attach, force-detach), IAM instance
profile (OCI Dynamic Groups match instances by rule — nothing to attach at launch time, see §13).

**OCI advantages in this module:** flex shapes with independent OCPU + memory sizing, fine-grained
cloud agent plugin control (10 plugins), predefined backup policies (gold/silver/bronze), boot from
existing boot volume, explicit `instance_state` desired-state control, compartment scoping.

### Implementation backlog (priority order)

#### AWS parity gaps — OCI provider supports these, module does not yet expose them

_None — all AWS parity gaps are now closed._

#### OCI-native features — no AWS equivalent, not yet in the module

_All OCI-native features are now implemented._

#### Examples

6. **`bastion` example** — SSH-less access via OCI Bastion service + dynamic group
7. **`multiple` / wrapper example** — showcase `for_each` across instances with shared defaults
