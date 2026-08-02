# state-seed

The dedicated home of terraform state: project `joshrobbinsuk-tf-state`, bucket
`gs://joshrobbinsuk-tf-state` (versioned, public-access prevented, deletion lien).
Every stack's `backend "gcs"` points here; see `factory/infra/BOOTSTRAP.md` for the
state layout.

This stack's own state is local and committed — the floor of the tower cannot store
its state in the bucket it defines.

Created by hand 2026-08-02 (commands in `factory/infra/BOOTSTRAP.md`), then imported:

```sh
terraform import google_project.seed joshrobbinsuk-tf-state
terraform import google_storage_bucket.terraform_state joshrobbinsuk-tf-state/joshrobbinsuk-tf-state
terraform import google_resource_manager_lien.keep "<project-number>/<lien-name>"
```

All three imported 2026-08-02; `terraform plan` is clean.
