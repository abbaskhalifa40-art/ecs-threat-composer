# modules/alb/main.tf
# An Application Load Balancer (ALB): the public front door. It accepts
# web traffic and forwards it to healthy copies of the app.
#
# HTTP only for now. HTTPS (port 443 + an ACM certificate) comes later,
# once there's a domain name to put on the certificate.

# Security groups are firewalls. This one allows web traffic in from
# anywhere, and only lets the ALB send traffic into our own VPC.
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTP in from the internet"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-alb-sg" }
}

# Rules are separate resources (the newer recommended style). Each rule
# is managed on its own, which avoids surprise changes to other rules.
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "to_vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "Forward to app tasks inside the VPC only"
  cidr_ipv4         = var.vpc_cidr
  from_port         = var.target_port
  to_port           = var.target_port
  ip_protocol       = "tcp"
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false # internet-facing
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  # Drops requests with malformed HTTP headers, a common hardening
  # setting flagged by security scanners like checkov.
  drop_invalid_header_fields = true
}

# A target group is the list of places the ALB sends traffic to.
# target_type "ip" is required for Fargate, because each task gets its
# own IP address rather than running on an EC2 instance you manage.
resource "aws_lb_target_group" "app" {
  name        = "${var.name}-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  # How long the ALB waits for in-flight requests to finish before
  # removing a task during a deploy. The default (300s) makes every
  # deploy slow, 30s is plenty for this app.
  deregistration_delay = 30

  # The ALB calls /health every 30s. If it gets a 200 back, the task is
  # healthy and gets traffic. If not, ECS replaces it.
  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# A listener waits for connections on a port and decides what to do with
# them. This one forwards everything on port 80 to the target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
