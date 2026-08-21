run "creates_reserved_public_ip" {
  command = apply

  module {
    source = "./examples/reserved-ip"
  }

  assert {
    condition     = output.instance_id != null
    error_message = "Instance must be created"
  }
  assert {
    condition     = output.reserved_public_ip != null
    error_message = "Reserved public IP must be created"
  }
  assert {
    condition     = output.reserved_public_ip != ""
    error_message = "Reserved public IP must have an address assigned"
  }
  assert {
    condition     = output.public_ip == output.reserved_public_ip
    error_message = "Instance public IP must match the reserved IP"
  }
  assert {
    condition     = output.secondary_reserved_public_ips["data"].ip_address != null
    error_message = "Secondary VNIC must have its own reserved public IP"
  }
  assert {
    condition     = output.secondary_reserved_public_ips["data"].ip_address != output.reserved_public_ip
    error_message = "Secondary reserved public IP must be distinct from the primary one"
  }
}
