variable "project_id" {
  description = "GCP project ID to bootstrap (the ID, not the display name)"
  type        = string
}

variable "region" {
  description = "GCP region for the state bucket"
  type        = string
  default     = "europe-west2"
}

variable "github_repo" {
  description = "owner/repo permitted to deploy via Workload Identity Federation"
  type        = string
  default     = "joshrobbinsuk/brokelads_cloud"
}

# WIF is pinned to this branch as well as the repo, so only deploy workflows
# running on the live branch can assume the deployer SA — not every workflow in
# the repo. Widen (or add prod's branch) when prod goes live.
variable "allowed_ref" {
  description = "git ref permitted to federate (e.g. refs/heads/dev)"
  type        = string
  default     = "refs/heads/dev"
}

variable "deployer_account_id" {
  description = "Account id for the CI deployer service account"
  type        = string
  default     = "gh-actions-deployer"
}

variable "pool_id" {
  description = "Workload Identity Pool id"
  type        = string
  default     = "github-pool"
}

variable "provider_id" {
  description = "Workload Identity Pool provider id"
  type        = string
  default     = "github-provider"
}

# Broad-but-pragmatic set so the deployer can apply the whole app stack
# (Cloud Run + Artifact Registry + Scheduler + Secret Manager + a runtime SA).
# Tighten later if you want least-privilege per-resource.
variable "deployer_roles" {
  description = "Project roles granted to the CI deployer SA"
  type        = list(string)
  default = [
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/cloudscheduler.admin",
    "roles/secretmanager.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/storage.admin",
    "roles/serviceusage.serviceUsageAdmin",
  ]
}
