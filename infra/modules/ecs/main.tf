# modules/ecs/main.tf
# Runs the app on ECS Fargate. Fargate means AWS runs the servers for
# you: you just say how much CPU and memory each container needs.
#
# The pieces:
#   cluster          - a logical group that services run in
#   task definition  - the recipe: which image, CPU, memory, ports, logs
#   service          - keeps N copies of the task running and registers
#                      them with the load balancer

# ---------------------------------------------------------------------
# Firewall for the tasks: only the ALB can reach the app port.
# ---------------------------------------------------------------------
resource "aws_security_group" "tasks" {
  name        = "${var.name}-tasks-sg"
  description = "Allow traffic from the ALB only"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-tasks-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  security_group_id            = aws_security_group.tasks.id
  description                  = "App port from the ALB"
  referenced_security_group_id = var.alb_sg_id # a security group, not an IP range
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
}

# Tasks need outbound HTTPS to pull their image from ECR and send logs
# to CloudWatch.
resource "aws_vpc_security_group_egress_rule" "https_out" {
  security_group_id = aws_security_group.tasks.id
  description       = "HTTPS out to ECR and CloudWatch"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# ---------------------------------------------------------------------
# Logging: everything the app prints goes to CloudWatch Logs.
# ---------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
}

# ---------------------------------------------------------------------
# IAM: the task EXECUTION role is what ECS itself uses to start your
# container (pull the image, write logs). It's different from a task
# role, which the app would use to call AWS services. This app doesn't
# call AWS, so it doesn't need a task role. Least privilege.
# ---------------------------------------------------------------------
resource "aws_iam_role" "execution" {
  name = "${var.name}-task-execution"

  # The trust policy: only the ECS tasks service may use this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# AWS's managed policy: allows pulling from ECR and writing to CloudWatch.
resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  # Container Insights gives detailed metrics but costs extra.
  # Left off for a learning project. Worth turning on in production.
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

# ---------------------------------------------------------------------
# Task definition: the recipe for running one copy of the app.
# ---------------------------------------------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # required for Fargate: each task gets its own network interface
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.execution.arn

  # ARM64 (AWS Graviton) is about 20% cheaper than x86 on Fargate, and
  # matches the image built on an Apple Silicon Mac.
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = var.name
    image     = var.image
    essential = true # if this container stops, the whole task stops

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    # Send container output (console.log etc.) to CloudWatch.
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "app"
      }
    }

    # Adds a tiny init process as PID 1, so the app shuts down cleanly
    # when ECS stops it (same fix as `docker run --init` locally).
    linuxParameters = {
      initProcessEnabled = true
    }
  }])
}

# ---------------------------------------------------------------------
# Service: keeps desired_count tasks running and wires them to the ALB.
# ---------------------------------------------------------------------
resource "aws_ecs_service" "app" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true # needed to reach ECR without a NAT gateway
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = var.container_port
  }

  # Give a new task 60s to start before health checks can fail it.
  health_check_grace_period_seconds = 60

  # If a new deployment keeps failing health checks, stop it and roll
  # back to the last working version automatically.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Rolling deploy: start the new task before stopping the old one, so
  # there's no downtime (allows up to 200% of desired_count briefly).
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # Wait for the service to be healthy before `apply` finishes, so a
  # broken deploy shows up as a failed apply rather than silently.
  wait_for_steady_state = true
}
