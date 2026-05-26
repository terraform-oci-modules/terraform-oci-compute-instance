run "creates_windows_instance" {
  command = apply

  module {
    source = "./examples/windows"
  }

  assert {
    condition     = output.instance_id != null
    error_message = "Windows instance must be created"
  }
  assert {
    condition     = output.public_ip != null
    error_message = "Windows instance must have a public IP (assign_public_ip = true)"
  }
  assert {
    condition     = output.instance_credentials != null
    error_message = "Windows credentials must be returned (is_windows_instance = true)"
  }
}
