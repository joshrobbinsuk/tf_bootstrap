# state-seed

The dedicated home of terraform state: project `joshrobbinsuk-tf-state`, bucket
`gs://joshrobbinsuk-tf-state` (versioned, public-access prevented, deletion lien,
`prevent_destroy`). Every stack's `backend "gcs"` points here. This stack's own state
is local and committed — the floor of the tower cannot store its state in the bucket
it defines.

## State layout

- `factory/` — the factory VM stack (`factory/infra`), migrated 2026-08-02 with
  `terraform init -migrate-state`.
- `brokelads/dev/` — the brokelads stack (`brokelads_cloud/terraform/gcp/dev`, 48
  resources), repointed 2026-08-02; its CI deployer SA holds
  `roles/storage.objectAdmin` on this bucket (granted by this stack).
- `finance/` — (reserved) the household finance app's workbench, when it lands.

Owner credentials (local applies) need no grant; CI service accounts get a bucket
IAM member here.

## Bootstrap provenance

Created by hand 2026-08-02, then imported so `terraform plan` is clean:

```sh
terraform import google_project.seed joshrobbinsuk-tf-state
terraform import google_storage_bucket.terraform_state joshrobbinsuk-tf-state/joshrobbinsuk-tf-state
terraform import google_resource_manager_lien.keep "<project-number>/<lien-name>"
```

The hand-made footprint that remains outside terraform: the superseded creation
commands above, and the gcloud `alpha` CLI component (installed locally to manage
liens).

## History

State previously lived in `gs://526938691325-terraform-state` inside the brokelads
project — a retired-ish stack holding the state of living ones, one project-deletion
away from orphaning everything. All consumers migrated out 2026-08-02; both objects
left in the old bucket are stale copies.

The old bucket is owned by `tf_bootstrap/gcp`, which also owns the brokelads WIF
pool and deployer SA (still live in brokelads CI). Correct removal of the bucket
alone: delete the `google_storage_bucket.terraform_state` resource (and its
`prevent_destroy`) from `tf_bootstrap/gcp` and apply — pending Josh's sign-off. The
WIF pool and deployer stay for as long as brokelads does.
