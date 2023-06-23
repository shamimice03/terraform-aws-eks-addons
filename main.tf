locals {
  aws_iam_oidc_provider_arn = var.oidc_provider_arn
  oidc_provider             = element(split("oidc-provider/", "${var.oidc_provider_arn}"), 1)
}


resource "aws_iam_role" "irsa_role" {
  name = var.irsa_role_name

  # Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = "${local.aws_iam_oidc_provider_arn}"
        }
        Condition = {
          StringEquals = {
            "${local.oidc_provider}:aud" : "sts.amazonaws.com",
            "${local.oidc_provider}:sub" : "system:serviceaccount:${var.namespace}:${var.serviceaccount}"
          }
        }
      },
    ]
  })

  tags = {
    Name = "${var.irsa_role_name}"
  }
}


# Associate IAM Role and Policy
resource "aws_iam_role_policy_attachment" "irsa_iam_role_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.irsa_role.name
}

output "irsa_iam_role_arn" {
  description = "IRSA Demo IAM Role ARN"
  value       = aws_iam_role.irsa_role.arn
}

