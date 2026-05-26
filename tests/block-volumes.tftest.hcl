run "creates_block_volumes" {
  command = apply

  module {
    source = "./examples/block-volumes"
  }

  assert {
    condition     = output.instance_id != null
    error_message = "Instance must be created"
  }
  assert {
    condition     = length(output.block_volumes) == 3
    error_message = "Expected 3 block volumes (data, archive, database)"
  }
  assert {
    condition     = length(output.block_volume_attachments) == 3
    error_message = "Expected 3 volume attachments"
  }
  assert {
    condition     = contains(keys(output.block_volumes), "data")
    error_message = "data volume (paravirtualized, high performance) must exist"
  }
  assert {
    condition     = contains(keys(output.block_volumes), "archive")
    error_message = "archive volume (paravirtualized, low cost) must exist"
  }
  assert {
    condition     = contains(keys(output.block_volumes), "database")
    error_message = "database volume (iSCSI, ultra high performance) must exist"
  }
}
