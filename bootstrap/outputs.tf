# outputs.tf
# Values printed after `terraform apply`. You'll need these in the next
# steps: the bucket name for the main infra's backend, and the ECR URL
# for pushing images. View them again any time with `terraform output`.

output "state_bucket_name" {
  description = "S3 bucket holding Terraform state for the main infra"
  value       = aws_s3_bucket.tfstate.bucket
}

output "ecr_repository_url" {
  description = "ECR URL to tag and push Docker images to"
  value       = aws_ecr_repository.app.repository_url
}

output "region" {
  description = "Region everything was created in"
  value       = var.region
}
