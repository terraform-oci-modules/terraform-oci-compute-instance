run "creates_flex_shape_instances" {
  command = apply

  module {
    source = "./examples/flex-shape"
  }

  assert {
    condition     = output.standard_flex_id != null
    error_message = "Standard flex instance must be created (BASELINE_1_1 - 100% baseline)"
  }
  assert {
    condition     = output.burstable_flex_id != null
    error_message = "Burstable flex instance must be created (BASELINE_1_2 - 50% baseline)"
  }
  assert {
    condition     = output.micro_flex_id != null
    error_message = "Micro burstable instance must be created (BASELINE_1_8 - 12.5% baseline)"
  }
}
