# Reserved (Static) Public IP

Configuration in this directory demonstrates how to assign a stable public IP address that survives instance replacement. Maps to `create_eip` in the AWS module.

An instance is created in a public subnet with `create_reserved_public_ip = true`, which allocates a new reserved (static) IP and attaches it to the instance.

Unlike `assign_public_ip`, a reserved IP persists through `terraform destroy` and can be reassigned to a replacement instance.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which can cost money (reserved public IP addresses are billed when unattached). Run `terraform destroy` when you no longer need these resources.

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

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_instance"></a> [instance](#module\_instance) | ../../ | n/a |
| <a name="module_vcn"></a> [vcn](#module\_vcn) | terraform-oci-modules/vcn/oci | ~> 0.7 |

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
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | OCID of the instance |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | The public IP address of the instance |
| <a name="output_reserved_public_ip"></a> [reserved\_public\_ip](#output\_reserved\_public\_ip) | The reserved public IP address |
<!-- END_TF_DOCS -->
