output "deployer_service_account_email" {
  description = "CI deployer SA — the app stack's GitHub Actions impersonates this"
  value       = google_service_account.deployer.email
}

output "workload_identity_provider" {
  description = "Full WIF provider resource name — pass to google-github-actions/auth"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_auth" {
  description = "Drop-in auth step for the deploy workflow"
  value       = <<-EOT
    - uses: google-github-actions/auth@v2
      with:
        workload_identity_provider: "${google_iam_workload_identity_pool_provider.github.name}"
        service_account: "${google_service_account.deployer.email}"
  EOT
}

output "backend_config" {
  description = "backend block template for consuming stacks (one prefix per app/env)"
  value       = <<-EOT
    terraform {
      backend "gcs" {
        bucket = "joshrobbinsuk-tf-state" # shared bucket, managed by state-seed/
        prefix = "<app>/<env>"
      }
    }
  EOT
}
