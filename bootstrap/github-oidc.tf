# github-oidc.tf
# Lets GitHub Actions log in to AWS WITHOUT storing any AWS keys in GitHub.
#
# How it works:
#   1. When a workflow runs, GitHub issues it a short-lived signed token
#      (an OIDC token) that says which repo, branch and environment it's
#      running from.
#   2. The workflow hands that token to AWS STS and asks to assume the
#      role below.
#   3. AWS checks the token was really signed by GitHub, and that the
#      repo and branch match the trust policy. If so, it returns
#      temporary credentials that expire within an hour.
# Nothing long-lived exists that could leak, unlike access keys.

# Register GitHub as a trusted identity provider in this AWS account.
# Only one of these can exist per account for this URL.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # "Audience": who the token is meant for. AWS STS expects this value.
  client_id_list = ["sts.amazonaws.com"]

  # No thumbprint_list needed: AWS now verifies GitHub's certificate
  # itself, so the old practice of pinning a thumbprint is unnecessary.
}

resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-github-actions"
  description = "Assumed by GitHub Actions in ${var.github_repo} via OIDC"

  # Credentials from this role last at most one hour.
  max_session_duration = 3600

  # The TRUST POLICY: who is allowed to use this role. This is the
  # important security part.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          # The token must be meant for AWS STS...
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

          # ...and must come from THIS repo, and only from either:
          #  - a job on the main branch (builds the image), or
          #  - a job using the "production" environment (deploys, which
          #    needs your manual approval in GitHub first).
          # Forks, other branches and pull requests can't assume it.
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_repo}:ref:refs/heads/main",
            "repo:${var.github_repo}:environment:production",
          ]
        }
      }
    }]
  })
}

# PERMISSIONS: what the role can do once assumed.
#
# Trade-off, stated honestly: Terraform creates IAM roles, VPCs, load
# balancers and ECS resources, so a tightly scoped policy for all of that
# is long and fiddly. For a solo learning project we attach
# AdministratorAccess, and lean on the trust policy above to limit WHO
# can use it (main branch or an approved production deploy only).
# A good next improvement: replace this with a custom least-privilege
# policy, and a separate read-only role for `terraform plan`.
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
