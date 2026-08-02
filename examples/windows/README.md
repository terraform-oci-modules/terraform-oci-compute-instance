# Windows Server

Configuration in this directory creates a Windows Server compute instance with RDP access.

Key differences from a Linux instance:

- `is_windows_instance = true` - enables Windows credential retrieval via `instance_credentials` output
- `assign_public_ip = true` - instance placed in a public subnet with IGW for RDP reachability
- No SSH key required; OCI generates an initial Administrator password retrievable via the console or `instance_credentials` output
- Boot volume backup policy set to silver

Maps to `get_password_data` in the AWS module.

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
| [oci_core_images.windows](https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_compartment_id"></a> [compartment\_id](#input\_compartment\_id) | The OCID of the compartment where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_instance_credentials"></a> [instance\_credentials](#output\_instance\_credentials) | Initial Windows credentials (username + password). Treat as sensitive |
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The OCID of the Windows instance |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | The public IP address of the Windows instance (for RDP access) |
<!-- END_TF_DOCS -->
