# Flex Shape

Configuration in this directory demonstrates the two flex shape modes available on OCI:

- **Standard flex** - full OCPU baseline; maps to AWS general-purpose instance sizing
- **Burstable flex** - 50% baseline OCPU utilization; maps to AWS T-series `cpu_credits = standard`

Both instances share the same private subnet backed by a NAT gateway.

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
| <a name="module_burstable_flex"></a> [burstable\_flex](#module\_burstable\_flex) | ../../ | n/a |
| <a name="module_micro_flex"></a> [micro\_flex](#module\_micro\_flex) | ../../ | n/a |
| <a name="module_standard_flex"></a> [standard\_flex](#module\_standard\_flex) | ../../ | n/a |
| <a name="module_vcn"></a> [vcn](#module\_vcn) | terraform-oci-modules/vcn/oci | ~> 0.6 |

## Resources

| Name | Type |
| ---- | ---- |
| [oci_core_images.oracle_linux](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id) | The OCID of the compartment where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_burstable_flex_id"></a> [burstable\_flex\_id](#output\_burstable\_flex\_id) | OCID of the burstable flex instance |
| <a name="output_micro_flex_id"></a> [micro\_flex\_id](#output\_micro\_flex\_id) | OCID of the micro burstable flex instance |
| <a name="output_standard_flex_id"></a> [standard\_flex\_id](#output\_standard\_flex\_id) | OCID of the standard flex instance |
<!-- END_TF_DOCS -->
