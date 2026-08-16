# Testing

The test suite lives in `tests/` - one `.tftest.hcl` file per example. All tests run from the module root via a single `terraform test` invocation.

## Prerequisites

- Terraform >= 1.7
- OCI credentials configured - any of:
  - Environment variables (`OCI_CLI_TENANCY`, `OCI_CLI_USER`, `OCI_CLI_FINGERPRINT`, `OCI_CLI_KEY_FILE`, `OCI_CLI_REGION`)
  - A config file at `~/.oci/config`
  - Instance principal (when running from an OCI compute instance)
- A target compartment OCID

## Quick start (free, no credentials needed)

`tests/unit_mappings.tftest.hcl` exercises input->config mapping logic
(availability-domain resolution, flex-shape detection, cloud agent plugin
alias resolution, NSG merging) against a mocked OCI provider - no real
resources, no OCI credentials, safe to run anytime:

```bash
terraform init
terraform test -filter=tests/unit_mappings.tftest.hcl
```

## Quick start (real resources, needs credentials)

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1.."
terraform init
terraform test -filter=tests/simple.tftest.hcl
```

## Running all tests

```bash
export TF_VAR_compartment_id="ocid1.compartment.oc1.."
terraform init
terraform test
```

## Notes

- All tests except `tests/unit_mappings.tftest.hcl` use `command = apply` - they create and destroy **real** OCI resources and will incur cost.
- The `windows` example creates a Windows Server 2022 instance and retrieves initial credentials - the instance is destroyed at the end of the test run.
- The `capacity-reservation` example creates a compute capacity reservation (`VM.Standard.E6.Flex`) in addition to the instance; both are destroyed at the end. It requires a non-zero service limit for `standard-e6-core-count-reservable` in your tenancy - check under **Governance & Administration → Limits, Quotas and Usage** in the OCI console. If the limit is 0, request an increase from Oracle Support before running this test. OCI returns a misleading `404-NotAuthorizedOrNotFound` error when the quota is zero.
- The `flex-shape` example creates three instances simultaneously; expect roughly 3× the cost of a single-instance example.
