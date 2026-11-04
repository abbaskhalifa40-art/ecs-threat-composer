# variables.tf
# Inputs for the main infrastructure. Only image_tag has no default,
# because you must always say exactly which image version to deploy.

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Used in resource names and tags. Must match the ECR repo name from bootstrap."
  type        = string
  default     = "ecs-threat-composer"
}

variable "image_tag" {
  description = "Image tag to deploy (the short git commit SHA, e.g. efd0e24)"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Port the app listens on inside the container"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "How many copies of the app (tasks) to run"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "CPU units per task (256 = 0.25 vCPU, the smallest size)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory per task in MB"
  type        = number
  default     = 512
}
