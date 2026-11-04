# main.tf
# The root module. It doesn't create much itself, it wires three modules
# together, passing outputs from one into the inputs of the next:
#
#   vpc  ->  alb  ->  ecs
#   (network)  (load balancer)  (the app)

# Look up the ECR repo bootstrap created, so we can build the image URL
# without hardcoding the account ID.
data "aws_ecr_repository" "app" {
  name = var.project_name
}

module "vpc" {
  source = "./modules/vpc"

  name     = var.project_name
  vpc_cidr = var.vpc_cidr
}

module "alb" {
  source = "./modules/alb"

  name              = var.project_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  public_subnet_ids = module.vpc.public_subnet_ids
  target_port       = var.container_port
}

module "ecs" {
  source = "./modules/ecs"

  name             = var.project_name
  region           = var.region
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.public_subnet_ids
  alb_sg_id        = module.alb.alb_sg_id
  target_group_arn = module.alb.target_group_arn
  image            = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"
  container_port   = var.container_port
  desired_count    = var.desired_count
  task_cpu         = var.task_cpu
  task_memory      = var.task_memory

  # The ECS service can only attach to the target group once the
  # load balancer listener exists. Without this, the first apply can
  # fail with "target group does not have an associated load balancer".
  depends_on = [module.alb]
}
