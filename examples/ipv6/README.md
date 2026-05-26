# IPv6 Dual-Stack

Configuration in this directory creates a dual-stack compute instance with both a public IPv4 address and an auto-assigned IPv6 address. Maps to `enable_primary_ipv6` / `ipv6_address_count` in the AWS module.

The VCN is created with `enable_ipv6 = true`. OCI assigns a /56 IPv6 prefix to the VCN dynamically at apply time; each subnet then gets a /64 derived from that prefix. Because the /56 is unknown before the VCN exists, this example requires two applies.

## Usage

**Step 1** — create the VCN and retrieve the assigned IPv6 prefix:

```bash
$ terraform init
$ terraform apply -target=module.vcn
$ terraform output vcn_ipv6_cidr_block
```

**Step 2** — set the prefix in `terraform.tfvars`, then apply the rest:

```hcl
# terraform.tfvars
vcn_ipv6_cidr_block = "<value from step 1 output>"
```

```bash
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
| <a name="output_availability_domain"></a> [availability\_domain](#output\_availability\_domain) | The availability domain where the instance was placed |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The OCID of the instance |
| <a name="output_private_ip"></a> [private\_ip](#output\_private\_ip) | The private IPv4 address of the instance |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | The public IPv4 address of the instance |
| <a name="output_vcn_ipv6_cidr_block"></a> [vcn\_ipv6\_cidr\_block](#output\_vcn\_ipv6\_cidr\_block) | The /56 IPv6 CIDR block assigned to the VCN by OCI |
<!-- END_TF_DOCS -->
