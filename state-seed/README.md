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
project — one stack holding the state of all the others. All consumers migrated out
2026-08-02, and the old bucket was destroyed the same day via `tf_bootstrap/gcp`
(force_destroy flipped in one apply, resource removed in the next). That stack keeps
the brokelads WIF pool and deployer SA, which stay for as long as brokelads does.
