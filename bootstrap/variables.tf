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
