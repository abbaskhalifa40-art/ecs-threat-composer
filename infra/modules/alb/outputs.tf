output "alb_dns_name" {
  description = "Public address of the load balancer"
  value       = aws_lb.this.dns_name
}

output "alb_sg_id" {
  description = "Passed to the ECS module so tasks only accept traffic from the ALB"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}
