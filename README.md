# ECS Threat Composer

Deploying AWS Threat Composer on ECS Fargate, with infrastructure in Terraform and CI/CD in GitHub Actions.

**Status:** work in progress

## Progress

- [x] App containerised and running locally in Docker
- [ ] Terraform bootstrap: S3 remote state and ECR repository
- [ ] Terraform modules: VPC, ALB, ECS Fargate
- [ ] HTTPS with ACM and Route 53
- [ ] GitHub Actions with OIDC: build, scan, deploy
- [ ] CloudWatch logging and monitoring

## Run locally

```bash
cd app
docker build -t threat-composer:local .
docker run --rm --init -p 3000:3000 threat-composer:local
```

Then open http://localhost:3000. Health check: http://localhost:3000/health

## Credits

Built as part of the CoderCo DevOps programme, using [omarabukar1/ecs-app](https://github.com/omarabukar1/ecs-app) as a reference. The app is AWS's open-source [Threat Composer](https://github.com/awslabs/threat-composer).
