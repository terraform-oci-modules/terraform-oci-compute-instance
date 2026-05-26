# Complete Compute Instance

Configuration in this directory demonstrates a production-style compute instance using most of the available module features.

What this example covers:

- **Flex shape** — 4 OCPU / 32 GB RAM (`VM.Standard.E4.Flex`)
- **Custom boot volume** — 100 GB, 20 VPU/s (Balanced), silver backup policy
- **Block volumes** — one balanced paravirtualized data volume (500 GB) and one archive volume (100 GB)
- **cloud-init user data** — base64-encoded startup script
- **Extended metadata** — arbitrary key-value pairs attached to the instance
- **Cloud agent plugins** — fine-grained control: monitoring, bastion, run-command, OSMS, and vulnerability scanning enabled; management and block-volume-mgmt disabled
- **IMDSv2 enforcement** — `metadata_options.is_http_tokens_enabled = true`
- **Network security group** — module-managed NSG with SSH and HTTP ingress rules
- **Preserve boot volume** — boot volume retained on instance termination

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which can cost money. Run `terraform destroy` when you no longer need these resources.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_oci"></a> [oci](#provider\_oci) | >= 6.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_instance"></a> [instance](#module\_instance) | ../../ | n/a |
| <a name="module_vcn"></a> [vcn](#module\_vcn) | terraform-oci-modules/vcn/oci | ~> 0.5 |

## Resources

| Name | Type |
| ---- | ---- |
| [oci_core_images.oracle_linux](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id) | The OCID of the compartment where resources will be created | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key string to inject into the instance | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_block_volumes"></a> [block\_volumes](#output\_block\_volumes) | Map of block volume attributes |
| <a name="output_boot_volume_id"></a> [boot\_volume\_id](#output\_boot\_volume\_id) | The OCID of the boot volume |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The OCID of the instance |
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | The OCID of the created NSG |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | The private IP address of the instance |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | The reserved public IP address |
<!-- END_TF_DOCS -->
