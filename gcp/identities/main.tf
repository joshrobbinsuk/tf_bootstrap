terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# APIs the BOOTSTRAP's OWN resources need — the state bucket (storage) and WIF
# (iam/iamcredentials/sts). Nothing else: the bootstrap stays app-agnostic, so
# the app's APIs (Cloud Run, Artifact Registry, Scheduler, Secret Manager) are
# the app stack's concern, enabled there next to the resources that use them.
# cloudresourcemanager + serviceusage are manual pre-reqs (see README) — TF needs
# them on to manage anything, including these.
locals {
  services = [
    "storage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each           = toset(local.services)
  service            = each.value
  disable_on_destroy = false
}

# Terraform state bucket — the GCS analogue of the AWS S3 state bucket.
# The per-project state bucket this stack used to create was retired 2026-08-02:
# state for all stacks now lives in the shared bucket managed by gcp/state.

# Keyless CI auth: GitHub Actions OIDC -> Workload Identity Federation ->
# impersonate the deployer service account. No static key is ever stored.
resource "google_service_account" "deployer" {
  account_id   = var.deployer_account_id
  display_name = "GitHub Actions deployer (${var.github_repo})"

  depends_on = [google_project_service.enabled]
}

# The deployer's provisioning power: a single GENERIC project role — not an
# app-specific one — so the CI identity can stand up any app stack itself, the
# same way the AWS side runs CI as a full admin. `editor` is broad-but-not-owner
# (no project-IAM / billing / project-delete); dial to `roles/owner` only if a
# stack needs to set project-level IAM. Keyless WIF + branch-pinning already make
# this safer than the AWS static admin key. (editor includes state-bucket access.)
resource "google_project_iam_member" "deployer" {
  project = var.project_id
  role    = var.deployer_role
  member  = "serviceAccount:${google_service_account.deployer.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "OIDC pool for GitHub Actions deploys"

  depends_on = [google_project_service.enabled]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Google requires a condition for the GitHub issuer. Restrict federation to
  # this one repo AND the deploy branch, so no other repo — and no other branch
  # or PR workflow within the repo — can assume the deployer.
  attribute_condition = "assertion.repository == \"${var.github_repo}\" && assertion.ref == \"${var.allowed_ref}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Only the named GitHub repo's OIDC identity may impersonate the deployer SA.
resource "google_service_account_iam_member" "wif_impersonation" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}
