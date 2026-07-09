# GCP Terraform Bootstrap

The GCP counterpart to the AWS bootstrap in the repo root. Creates the
foundational infrastructure the BrokeLads GCP app stacks depend on:

- **GCS bucket** for Terraform state (versioned) — the analogue of the AWS S3
  state bucket. The GCS backend locks state natively, so there is **no**
  DynamoDB-equivalent lock table.
- **Workload Identity Federation** — a pool + GitHub OIDC provider + a deployer
  service account, so GitHub Actions deploys **keylessly** (no stored
  credential — an upgrade over the AWS side's static access key).

Like the AWS root, this uses **local state** and is **applied once, by hand** —
it's the bootstrap, so it can't store its own state in the bucket it creates.
This is the one sanctioned exception to "provision only via CI".

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
  **generic** project role (`deployer_role`, default `roles/editor`) so it can
  stand up app stacks itself — the same way the AWS side runs CI as an admin,
  but keyless (WIF) and branch-pinned. It's generic, not app-specific
  (`run.admin` and friends never leak in here). Dial to `roles/owner` if a stack
  needs project-level IAM, or tighten below `editor` for least-privilege later.
- WIF is restricted by `attribute_condition` to the single repo
  `joshrobbinsuk/brokelads_cloud` **and** the deploy branch (`allowed_ref`,
  default `refs/heads/dev`) — no other repo, branch, or PR workflow can assume
  the deployer. Widen `allowed_ref` (or add prod's branch) when prod goes live.
- The AWS root is untouched; this is an independent Terraform root with its own
  local state.
