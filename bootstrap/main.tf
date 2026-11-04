# main.tf
# Creates the two things the rest of the project depends on:
#   1. An S3 bucket to store Terraform state for the main infrastructure
#   2. An ECR repository to store the app's Docker images

# ---------------------------------------------------------------------
# Look up the AWS account ID of whoever is running Terraform.
# We use it to make the bucket name unique, and it means the account ID
# is never hardcoded in the repo.
# ---------------------------------------------------------------------
data "aws_caller_identity" "current" {}

locals {
  # S3 bucket names are global across ALL AWS accounts, so adding the
  # account ID and region avoids clashing with someone else's bucket.
  state_bucket_name = "${var.project_name}-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"
}

# =====================================================================
# 1. TERRAFORM STATE BUCKET
# =====================================================================

resource "aws_s3_bucket" "tfstate" {
  bucket = local.state_bucket_name

  # Safety net: Terraform will refuse to destroy this bucket. Losing the
  # state file means Terraform forgets what it built, which is painful
  # to recover from. To delete it on purpose, remove this block first.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning keeps every old copy of the state file. If a bad apply
# corrupts state, you can roll back to a previous version.
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt everything stored in the bucket. State files can contain
# sensitive values (passwords, IPs, ARNs), so this matters.
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # S3-managed keys, free
    }
  }
}

# Block every form of public access. A public state bucket is one of the
# most common cloud security mistakes.
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Old state versions pile up over time. Delete versions older than 90
# days so storage doesn't grow forever. The current version is never
# touched by this rule.
resource "aws_s3_bucket_lifecycle_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {} # applies to every object in the bucket

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # Versioning must be on before lifecycle rules for old versions apply.
  depends_on = [aws_s3_bucket_versioning.tfstate]
}

# =====================================================================
# 2. ECR REPOSITORY (private Docker registry)
# =====================================================================

resource "aws_ecr_repository" "app" {
  name = var.project_name

  # IMMUTABLE means a tag can't be overwritten once pushed. Every image
  # is tagged with its git commit SHA, so you always know exactly which
  # code is running, and a deploy can't be silently swapped. (This is
  # why we won't use a "latest" tag.)
  image_tag_mutability = "IMMUTABLE"

  # Scan each image for known vulnerabilities (CVEs) when it's pushed.
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # Lets `terraform destroy` delete the repo even if it still has images.
  # Fine for a learning project. In a real company you'd leave this off.
  force_delete = true
}

# Keep only the most recent images. Old images cost storage and are
# rarely needed, so ECR deletes anything beyond the newest N.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the last ${var.ecr_keep_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_keep_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
