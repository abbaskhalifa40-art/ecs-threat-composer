# versions.tf
# Pins the Terraform and provider versions so the code behaves the same
# on every machine and in CI. Without pins, a new release can change
# behaviour or break your code without you touching anything.

terraform {
  # 1.10+ is needed for S3 native state locking (use_lockfile), which we
  # use in the main infra instead of a DynamoDB lock table.
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # "~> 6.0" means any 6.x version, but never 7.0. Minor updates are
      # fine, major versions can contain breaking changes.
      version = "~> 6.0"
    }
  }

  # No backend block here on purpose. This folder creates the S3 bucket
  # that will hold state for everything else, so it can't store its own
  # state in that bucket before it exists (chicken and egg). Its state
  # stays in a local terraform.tfstate file, which .gitignore keeps out
  # of GitHub.
}
