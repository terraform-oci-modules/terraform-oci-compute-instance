run "creates_simple_instance" {
  command = apply

  module {
    source = "./examples/simple"
  }

  assert {
    condition     = output.instance_id != null
    error_message = "Instance must be created"
  }
  assert {
    condition     = output.vcn_id != null
    error_message = "Supporting VCN must be created"
  }
  assert {
    condition     = output.private_subnet_id != null
    error_message = "Private subnet must exist"
  }
  assert {
    condition     = output.private_ip != null
    error_message = "Instance must have a private IP"
  }
  assert {
    condition     = output.availability_domain != null
    error_message = "Availability domain must be resolved and returned"
  }
}
