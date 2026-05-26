run "creates_capacity_reservation_instance" {
  command = apply

  module {
    source = "./examples/capacity-reservation"
  }

  assert {
    condition     = output.capacity_reservation_id != null
    error_message = "Capacity reservation must be created"
  }
  assert {
    condition     = output.instance_id != null
    error_message = "Instance must be created targeting the capacity reservation"
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
