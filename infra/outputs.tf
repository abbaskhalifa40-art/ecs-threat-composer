# outputs.tf

output "app_url" {
  description = "Open this in your browser once the service is healthy"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "log_group" {
  description = "CloudWatch log group where the app's logs go"
  value       = module.ecs.log_group_name
}
