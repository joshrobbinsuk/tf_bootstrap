# The state seed: one project holding one bucket — the terraform state for every
# stack. This is the floor of the bootstrap tower, so its own state is local and
# committed, like the sibling gcp/ stack. Everything here was created by hand on
# 2026-08-02 and imported; the import commands are in the README.

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  region = "europe-west2"
}

locals {
  project_id      = "joshrobbinsuk-tf-state"
  billing_account = "01D225-C3E792-3C3CC7"
}

resource "google_project" "seed" {
  name            = "tf-state"
  project_id      = local.project_id
  billing_account = local.billing_account

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "terraform_state" {
  name                        = local.project_id
  project                     = google_project.seed.project_id
  location                    = "EUROPE-WEST2"
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

# CI identities that keep their stack's state here. Owner credentials (Josh,
# local applies) need no grant; service accounts do.
resource "google_storage_bucket_iam_member" "brokelads_deployer" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:gh-actions-deployer@526938691325.iam.gserviceaccount.com"
}

# Belt to the prevent_destroy braces: the lien makes even a console/gcloud
# project deletion a deliberate two-step.
resource "google_resource_manager_lien" "keep" {
  parent       = "projects/${google_project.seed.number}"
  restrictions = ["resourcemanager.projects.delete"]
  origin       = "bootstrap"
  reason       = "Holds terraform state for all projects - deleting this orphans every terraform-managed stack"
}
