# providers.tf
# Tells Terraform which cloud to talk to and where.

provider "aws" {
  region = var.region

  # No credentials or profile here. Terraform picks them up from your
  # environment, so run `export AWS_PROFILE=abbas` first. Keeping keys
  # out of code means they can never be committed by accident.

  # default_tags are added to every resource this provider creates.
  # Tags make it easy to see what belongs to this project, and to filter
  # costs by project in the billing console.
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Stack     = "bootstrap"
    }
  }
}
