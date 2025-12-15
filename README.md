# Terraform Bootstrap

This project creates the foundational infrastructure for Terraform state management:
- S3 bucket for storing Terraform state files
- DynamoDB table for state locking

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0 installed

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

4. Note the outputs - you'll need these values for other Terraform projects:
   - `state_bucket_name`: Use this as the bucket in backend configs
   - `dynamodb_table_name`: Use this for state locking

## Important Notes

- This uses **local state** (terraform.tfstate file)
- Keep the `terraform.tfstate` file safe - commit it to this repo or store securely
- This only needs to be run once per AWS account
- The resources created here will be used by all other Terraform projects in this account

## Outputs

After running `terraform apply`, you'll see a `backend_config` output showing the exact configuration to use in your other projects.

## Cleanup

To destroy these resources (only if you're sure no other projects are using them):
```bash
terraform destroy
```

**Warning**: Only destroy if you've migrated all state files elsewhere or no longer need them.
