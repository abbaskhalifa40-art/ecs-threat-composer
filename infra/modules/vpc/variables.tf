variable "name" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the VPC, e.g. 10.0.0.0/16"
  type        = string
}

variable "az_count" {
  description = "How many availability zones to spread subnets across (an ALB needs at least 2)"
  type        = number
  default     = 2
}
