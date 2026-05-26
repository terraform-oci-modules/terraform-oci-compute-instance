run "creates_complete_instance" {
  command = apply

  module {
    source = "./examples/complete"
  }

  assert {
    condition     = output.instance_id != null
    error_message = "Instance must be created"
  }
  assert {
    condition     = output.private_ip != null
    error_message = "Instance must have a private IP"
  }
  assert {
    condition     = output.public_ip == null || output.public_ip == ""
    error_message = "No public IP expected (private subnet, assign_public_ip = false)"
  }
  assert {
    condition     = output.boot_volume_id != null
    error_message = "Boot volume OCID must be returned"
  }
  assert {
    condition     = length(output.block_volumes) == 2
    error_message = "Expected 2 block volumes (data + logs)"
  }
  assert {
    condition     = contains(keys(output.block_volumes), "data")
    error_message = "data block volume must exist"
  }
  assert {
    condition     = contains(keys(output.block_volumes), "logs")
    error_message = "logs block volume must exist"
  }
  assert {
    condition     = output.nsg_id != null
    error_message = "NSG must be created (create_nsg = true)"
  }
}
