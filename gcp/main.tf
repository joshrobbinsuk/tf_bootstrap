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

# APIs the project needs. The bootstrap's OWN prerequisites
# (cloudresourcemanager + serviceusage) must be enabled by hand before the
# first apply — see README. These enable the rest for the app stack.
locals {
  services = [
    "storage.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudscheduler.googleapis.com",
    "secretmanager.googleapis.com",
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
# The GCS backend does state locking natively, so there is no DynamoDB
# equivalent to create. Bucket names are global; the project id (also global)
# keeps it unique.
resource "google_storage_bucket" "terraform_state" {
  name                        = "${var.project_id}-terraform-state"
  location                    = var.region
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  # State is precious — block a stray `terraform destroy` from tearing the
  # bucket down. Remove deliberately if you ever really need to delete it.
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.enabled]
}

# Keyless CI auth: GitHub Actions OIDC -> Workload Identity Federation ->
# impersonate the deployer service account. No static key is ever stored.
resource "google_service_account" "deployer" {
  account_id   = var.deployer_account_id
  display_name = "GitHub Actions deployer (${var.github_repo})"

  depends_on = [google_project_service.enabled]
}

resource "google_project_iam_member" "deployer_roles" {
  for_each = toset(var.deployer_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.deployer.email}"
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
