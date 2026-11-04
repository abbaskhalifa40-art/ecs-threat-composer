variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  description = "Used to limit where the ALB can send traffic"
  type        = string
}

variable "public_subnet_ids" {
  description = "An ALB must span at least two subnets in different AZs"
  type        = list(string)
}

variable "target_port" {
  description = "Port the app listens on"
  type        = number
}

variable "health_check_path" {
  type    = string
  default = "/health"
}
