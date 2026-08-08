# Secondary Network Interface

Configuration in this directory demonstrates attaching a secondary VNIC to an instance after launch, in addition to its primary VNIC. Maps to `secondary_network_interface` in the AWS EC2 instance module.

An instance is launched with its primary VNIC in one private subnet, then a second VNIC is attached into a separate subnet via `oci_core_vnic_attachment`.

## Post-launch OS configuration

This example (and the `secondary_network_interface` variable in general) only attaches the VNIC
at the infrastructure level. OCI does not run DHCP on secondary VNICs, so after apply the second
interface exists inside the instance (e.g. as `ens5`) but has no IP address and is down.

On Oracle Linux, bring it up with the preinstalled `oci-utils` package:

```bash
sudo oci-network-config configure
```

On other distros, configure the interface manually with a static address matching the VNIC's
assigned private IP (see the `secondary_network_interfaces` output for the resolved address) -
DHCP will not work even if the OS attempts it.

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
| <a name="output_instance_id"></a> [instance\_id](#output\_instance\_id) | The OCID of the instance |
| <a name="output_primary_private_ip"></a> [primary\_private\_ip](#output\_primary\_private\_ip) | The private IP address of the primary VNIC |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | The OCIDs of the private subnets |
| <a name="output_secondary_network_interfaces"></a> [secondary\_network\_interfaces](#output\_secondary\_network\_interfaces) | Resolved attributes of the secondary VNICs: {vnic\_id, nic\_index, private\_ip, public\_ip, mac\_address} |
| <a name="output_vcn_id"></a> [vcn\_id](#output\_vcn\_id) | The OCID of the VCN |
<!-- END_TF_DOCS -->
