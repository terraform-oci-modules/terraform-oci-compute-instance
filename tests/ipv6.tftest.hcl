run "creates_ipv6_instance" {
  command = apply

  module {
    source = "./examples/ipv6"
  }

  assert {
    condition     = output.instance_id != null
    error_message = "Instance must be created"
  }
  assert {
    condition     = output.vcn_ipv6_cidr_block != null
    error_message = "VCN must have an IPv6 /56 CIDR assigned (enable_ipv6 = true)"
  }
  assert {
    condition     = output.public_ip != null
    error_message = "Instance must have a public IPv4 address (assign_public_ip = true)"
  }
  assert {
    condition     = output.private_ip != null
    error_message = "Instance must have a private IPv4 address"
  }
  assert {
    condition     = output.availability_domain != null
    error_message = "Availability domain must be resolved and returned"
  }
}
