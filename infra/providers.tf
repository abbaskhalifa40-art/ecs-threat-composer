# providers.tf

provider "aws" {
  region = var.region

  # Credentials come from AWS_PROFILE locally, and from OIDC in GitHub
  # Actions later. Nothing secret ever goes in the code.

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Stack     = "infra"
    }
  }
}
