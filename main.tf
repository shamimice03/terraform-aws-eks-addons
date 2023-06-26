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
  policy_arn = "arn:aws:iam::391178969547:policy/EBSCSIPolicy"
  role       = aws_iam_role.irsa_role.name
}

output "irsa_iam_role_arn" {
  description = "IRSA Demo IAM Role ARN"
  value       = aws_iam_role.irsa_role.arn
}

# ######################################################################
# # EBS CSI Add-on
# ######################################################################

resource "aws_eks_addon" "example" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.irsa_role.arn
}