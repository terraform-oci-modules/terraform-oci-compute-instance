################################################################################
# Mock unit tests: fast, free, no real OCI resources.
#
# Exercises input->config mapping logic (AD resolution, flex-shape detection,
# cloud agent plugin alias resolution, NSG merging) against the module root
# with a mocked OCI provider (command = plan). Run on its own:
#   terraform test -filter=tests/unit_mappings.tftest.hcl
################################################################################

mock_provider "oci" {
  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [
        { name = "AD-1" },
        { name = "AD-2" },
        { name = "AD-3" },
      ]
    }
  }

  mock_data "oci_core_vnic_attachments" {
    defaults = {
      vnic_attachments = [{ vnic_id = "ocid1.vnic.oc1..aaaaaaaaunit" }]
    }
  }
}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  subnet_id      = "ocid1.subnet.oc1..aaaaaaaaunit"
  source_id      = "ocid1.image.oc1..aaaaaaaaunit"
}

# --- Availability domain resolution -------------------------------------------

run "availability_domain_resolves_to_ad_name" {
  command = plan

  variables {
    availability_domain = 2
  }

  assert {
    condition     = oci_core_instance.this[0].availability_domain == "AD-2"
    error_message = "availability_domain = 2 must resolve to the tenancy's AD-2 name"
  }
}

# --- Flex shape detection ------------------------------------------------------

run "flex_shape_gets_shape_config_block" {
  command = plan

  variables {
    shape = "VM.Standard.E4.Flex"
    shape_config = {
      ocpus         = 4
      memory_in_gbs = 32
    }
  }

  assert {
    condition     = oci_core_instance.this[0].shape_config[0].ocpus == 4
    error_message = "a shape ending in .Flex must emit a shape_config block with the given ocpus"
  }
}

run "fixed_shape_omits_shape_config_block" {
  command = plan

  variables {
    shape = "VM.Standard2.1"
    shape_config = {
      ocpus = 4
    }
  }

  assert {
    condition     = length(oci_core_instance.this[0].shape_config) == 0
    error_message = "a fixed (non-.Flex) shape must omit the shape_config block entirely, even if shape_config values are set"
  }
}

# --- Cloud agent plugin alias resolution ---------------------------------------

run "plugin_alias_resolves_to_oci_name" {
  command = plan

  variables {
    cloud_agent_plugins = {
      monitoring = "ENABLED"
    }
  }

  assert {
    condition     = contains([for p in oci_core_instance.this[0].agent_config[0].plugins_config : p.name], "Compute Instance Monitoring")
    error_message = "cloud_agent_plugins alias 'monitoring' must resolve to the OCI plugin name 'Compute Instance Monitoring'"
  }
}

run "plugin_unknown_alias_passes_through_verbatim" {
  command = plan

  variables {
    cloud_agent_plugins = {
      "Custom Direct Plugin Name" = "DISABLED"
    }
  }

  assert {
    condition     = contains([for p in oci_core_instance.this[0].agent_config[0].plugins_config : p.name], "Custom Direct Plugin Name")
    error_message = "an unrecognized cloud_agent_plugins key must be passed through verbatim as the OCI plugin name"
  }
}

# --- NSG merging -----------------------------------------------------------

run "nsg_ids_merges_user_supplied_and_module_created" {
  # The module-created NSG's id is a resource attribute, unknown until apply -
  # apply against the mock provider to resolve it. This also doubles as a
  # regression test for output "instance_all_attributes" needing
  # sensitive = true: without that, this apply fails with "Output refers to
  # sensitive values" (metadata reads the sensitive ssh_authorized_keys
  # variable in a conditional, tainting the whole instance resource/output;
  # try()-over-a-not-yet-created-resource happened to mask this at plan time
  # only, so terraform plan alone never caught it).
  command = apply

  variables {
    create_nsg = true
    nsg_vcn_id = "ocid1.vcn.oc1..aaaaaaaaunit"
    nsg_ids    = ["ocid1.networksecuritygroup.oc1..aaaaaaaaexisting"]
  }

  assert {
    condition     = contains(oci_core_instance.this[0].create_vnic_details[0].nsg_ids, "ocid1.networksecuritygroup.oc1..aaaaaaaaexisting")
    error_message = "all_nsg_ids must include a user-supplied existing NSG"
  }

  assert {
    condition     = length(oci_core_instance.this[0].create_vnic_details[0].nsg_ids) == 2
    error_message = "all_nsg_ids must include both the user-supplied NSG and the module-created one"
  }
}

# --- ignore_image_changes resource selection -----------------------------------

run "ignore_image_changes_selects_alternate_resource" {
  command = plan

  variables {
    ignore_image_changes = true
  }

  assert {
    condition     = length(oci_core_instance.this) == 0
    error_message = "ignore_image_changes = true must not create oci_core_instance.this"
  }

  assert {
    condition     = length(oci_core_instance.ignore_image) == 1
    error_message = "ignore_image_changes = true must create oci_core_instance.ignore_image instead"
  }
}

# --- Cloud agent plugin names match what OCI offers ----------------------------

run "plugin_aliases_use_current_oci_names" {
  command = plan

  variables {
    cloud_agent_plugins = {
      run_command             = "ENABLED"
      java_management_service = "ENABLED"
      osms                    = "ENABLED"
    }
  }

  assert {
    condition = (
      toset([for p in oci_core_instance.this[0].agent_config[0].plugins_config : p.name]) ==
      toset(["Compute Instance Run Command", "Oracle Java Management Service", "OS Management Hub Agent"])
    )
    error_message = "run_command, java_management_service and osms must map to the plugin names OCI lists today"
  }
}

run "plugin_rejects_removed_autonomous_linux_alias" {
  command = plan

  variables {
    cloud_agent_plugins = { autonomous_linux = "ENABLED" }
  }

  expect_failures = [var.cloud_agent_plugins]
}

run "plugin_rejects_bad_state" {
  command = plan

  variables {
    cloud_agent_plugins = { monitoring = "ON" }
  }

  expect_failures = [var.cloud_agent_plugins]
}

run "plugin_rejects_alias_and_replacement_together" {
  command = plan

  variables {
    cloud_agent_plugins = {
      osms              = "ENABLED"
      os_management_hub = "DISABLED"
    }
  }

  expect_failures = [oci_core_instance.this]
}

run "plugin_rejects_alias_and_full_name_together" {
  command = plan

  variables {
    cloud_agent_plugins = {
      bastion   = "ENABLED"
      "Bastion" = "ENABLED"
    }
  }

  expect_failures = [oci_core_instance.this]
}

# --- Preemptible action --------------------------------------------------------

run "preemptible_action_defaults_to_terminate" {
  command = plan

  variables {
    preemptible_instance_config = { preserve_boot_volume_on_termination = true }
  }

  assert {
    condition     = oci_core_instance.this[0].preemptible_instance_config[0].preemption_action[0].type == "TERMINATE"
    error_message = "preemptible_instance_config.action must default to TERMINATE"
  }
  assert {
    condition     = oci_core_instance.this[0].preemptible_instance_config[0].preemption_action[0].preserve_boot_volume == true
    error_message = "preserve_boot_volume_on_termination must reach preemption_action.preserve_boot_volume"
  }
}

run "preemptible_rejects_stop" {
  command = plan

  variables {
    preemptible_instance_config = { action = "STOP" }
  }

  expect_failures = [var.preemptible_instance_config]
}

# --- Maintenance recovery ------------------------------------------------------

run "recovery_action_reaches_availability_config" {
  command = plan

  variables {
    recovery_action = "STOP_INSTANCE"
  }

  assert {
    condition     = oci_core_instance.this[0].availability_config[0].recovery_action == "STOP_INSTANCE"
    error_message = "recovery_action must reach availability_config.recovery_action"
  }
}

run "recovery_action_unset_sends_no_availability_config" {
  command = plan

  assert {
    condition     = length(oci_core_instance.this[0].availability_config) == 0
    error_message = "with recovery_action unset, no availability_config block must be sent"
  }
}

run "recovery_action_rejects_aws_values" {
  command = plan

  variables {
    recovery_action = "TERMINATE"
  }

  expect_failures = [var.recovery_action]
}
