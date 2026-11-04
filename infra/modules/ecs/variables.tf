variable "name" {
  type = string
}

variable "region" {
  description = "Needed for the CloudWatch logging config"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  description = "Only this security group may reach the tasks"
  type        = string
}

variable "target_group_arn" {
  type = string
}

variable "image" {
  description = "Full image URL including tag"
  type        = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
  type = number
}

variable "task_cpu" {
  type = number
}

variable "task_memory" {
  type = number
}

variable "log_retention_days" {
  description = "How long CloudWatch keeps logs. Shorter = cheaper."
  type        = number
  default     = 14
}
