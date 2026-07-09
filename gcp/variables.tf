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

# Generic (not app-specific) project role for the CI deployer, so it can
# provision app stacks itself. Defaults to owner because a typical app stack sets
# RESOURCE-level IAM (a public Cloud Run invoker binding, granting a runtime SA
# access to secrets) and roles/editor CANNOT set IAM policy of any kind. Drop to
# roles/editor for apps that never touch IAM. Either way it's keyless (WIF) +
# branch-pinned, so safer than the AWS static admin key.
variable "deployer_role" {
  description = "Generic project role granted to the CI deployer SA"
  type        = string
  default     = "roles/owner"
}
