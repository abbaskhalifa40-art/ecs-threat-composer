# versions.tf
# Same version pins as bootstrap, plus a remote backend: state for the
# main infrastructure lives in the S3 bucket that bootstrap created.

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state in S3. The bucket name is NOT written here, because it
  # contains the AWS account ID. It's passed in at init time instead:
  #   terraform init -backend-config="bucket=<state bucket name>"
  # (Backend blocks can't use variables, so this "partial config" is
  # the standard way to keep account-specific values out of code.)
  backend "s3" {
    key     = "infra/terraform.tfstate" # path of the state file in the bucket
    region  = "eu-west-2"
    encrypt = true

    # S3 native locking (Terraform 1.10+). Writes a .tflock file next to
    # the state so two people (or two pipelines) can't apply at once.
    # Replaces the old DynamoDB lock table.
    use_lockfile = true
  }
}
