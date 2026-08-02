# gcp/identities — per-app CI identities

One instance per app that runs terraform from CI. Human-applied (CI cannot
create the credentials it logs in with); the app repo's own stack is then fully
CI-driven — plan on PR, apply on merge. Terraform state for apps lives in the
shared bucket owned by `gcp/state`, which also grants each deployer its bucket
access.

Per app this provides **Workload Identity Federation** — a pool + GitHub OIDC
provider + a deployer service account pinned to one repo and branch, so GitHub
Actions deploys **keylessly** (no stored credential — an upgrade over the AWS
side's static access key).

Currently instantiated for **brokelads** (values in `terraform.tfvars`); the
next app generalises this from one hardcoded instance to a block per app.

Like the AWS root, this uses **local state** and is **applied once, by hand** —
it's the identity floor, so CI can't be what provisions it. This is the one
sanctioned exception to "provision only via CI".

## Prerequisites

- `gcloud` installed and authenticated, **and** ADC set (Terraform reads ADC,
  not the gcloud CLI login):
  ```bash
  gcloud auth login
  gcloud auth application-default login
  gcloud config set project <PROJECT_ID>
  ```
- A billing account **linked** to the project.
- The bootstrap's own two APIs enabled first (Terraform needs these on to
  manage everything else, including enabling the remaining APIs):
  ```bash
  gcloud services enable cloudresourcemanager.googleapis.com serviceusage.googleapis.com
  ```

## Usage

```bash
cd gcp
terraform init
terraform plan  -var project_id=<PROJECT_ID>
terraform apply -var project_id=<PROJECT_ID>
```

If an apply ever fails because a resource used an API that was enabled seconds
earlier (enablement can lag), just re-run `terraform apply` — it's idempotent.

## Outputs (feed these into the app stack)

- `state_bucket_name` → the app stack's `backend "gcs" { bucket = ... }`.
- `workload_identity_provider` + `deployer_service_account_email` → the
  `google-github-actions/auth` step in the deploy workflow. The
  `github_actions_auth` output prints that step ready to paste.
- `backend_config` prints the full `backend "gcs"` block (one `prefix` per env).

## Notes

- The bootstrap is **app-agnostic** — it provisions only a state backend and a
  CI identity, nothing about any particular app. The deployer SA gets one
  **generic** project role (`deployer_role`, default `roles/owner`) so it can
  stand up app stacks itself — the same way the AWS side runs CI as an admin,
  but keyless (WIF) and branch-pinned. Owner is the default because a typical app
  stack sets resource-level IAM (public Cloud Run invoker, runtime-SA secret
  access) and `roles/editor` can't set IAM policy at all. It's generic, not
  app-specific (`run.admin` and friends never leak in here). Drop to
  `roles/editor` for an app that never touches IAM.
- WIF is restricted by `attribute_condition` to the single repo
  `joshrobbinsuk/brokelads_cloud` **and** the deploy branch (`allowed_ref`,
  default `refs/heads/dev`) — no other repo, branch, or PR workflow can assume
  the deployer. Widen `allowed_ref` (or add prod's branch) when prod goes live.
- The AWS root is untouched; this is an independent Terraform root with its own
  local state.
