# Block Volumes

Configuration in this directory demonstrates attaching additional block volumes to a compute instance.

Three volume attachment types are shown:

- **Paravirtualized** — highest throughput, recommended for most workloads; silver backup policy
- **Paravirtualized (gold)** — same attachment type with a more aggressive backup policy
- **iSCSI** — network-attached block storage; requires manual discovery inside the OS

Maps to `ebs_block_device` in the AWS module.

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
| <a name="output_block_volume_attachments"></a> [block\_volume\_attachments](#output\_block\_volume\_attachments) | Block volume attachment details (includes iSCSI connection info) |
| <a name="output_block_volumes"></a> [block\_volumes](#output\_block\_volumes) | Map of block volume attributes (id, availability\_domain, size\_in\_gbs) |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The OCID of the instance |
<!-- END_TF_DOCS -->
