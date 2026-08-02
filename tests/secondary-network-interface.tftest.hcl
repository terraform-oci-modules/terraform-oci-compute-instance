run "creates_secondary_network_interface" {
  command = apply

  module {
    source = "./examples/secondary-network-interface"
  }

  assert {
    condition     = output.instance_id != null
    error_message = "Instance must be created"
  }
  assert {
    condition     = length(output.private_subnet_ids) == 2
    error_message = "VCN must have two private subnets (primary + secondary VNIC)"
  }
  assert {
    condition     = output.primary_private_ip != null
    error_message = "Instance must have a primary private IP"
  }
  assert {
    condition     = output.secondary_network_interfaces["data"].vnic_id != null
    error_message = "Secondary VNIC must be attached"
  }
  assert {
    condition     = output.secondary_network_interfaces["data"].private_ip != null
    error_message = "Secondary VNIC must have a private IP resolved"
  }
}
