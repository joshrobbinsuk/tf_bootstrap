variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket and DynamoDB table names"
  type        = string
  default     = "initial"
}
