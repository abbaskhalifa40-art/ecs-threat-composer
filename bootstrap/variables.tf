# variables.tf
# Inputs for this folder. Defaults are set so `terraform apply` works
# with no extra flags, but anything can be overridden, for example:
#   terraform apply -var="region=eu-west-1"

variable "region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "eu-west-2" # London
}

variable "project_name" {
  description = "Short name used in resource names and tags"
  type        = string
  default     = "ecs-threat-composer"
}

variable "ecr_keep_images" {
  description = "How many images to keep in ECR before old ones are deleted"
  type        = number
  default     = 10
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the Actions role, as owner/name"
  type        = string
  default     = "abbaskhalifa40-art/ecs-threat-composer"
}

variable "github_repo_subject" {
  description = "How GitHub identifies the repo in its OIDC token: owner@owner_id/repo@repo_id"
  type        = string

  # GitHub's OIDC tokens include permanent numeric IDs for the owner and
  # repo, not just their names. Names can be reused (delete a repo, and
  # someone else could create one with the same name), but IDs can't, so
  # matching on IDs means only THIS exact repo can assume the role.
  # Found by checking the failed AssumeRoleWithWebIdentity event in
  # CloudTrail. These IDs are public, not secret.
  default = "abbaskhalifa40-art@352087120/ecs-threat-composer@1446012140"
}
