# IAM Control Plane Role & Policy
resource "aws_iam_role" "controlplane_role" {
  name = "${var.cluster_name}-controlplane-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "controlplane_role_eksclusterpolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.controlplane_role.name
}

# Allow onprem network to access control plane
resource "aws_security_group" "onprem" {
  name        = "${var.cluster_name}-onprem-sg"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "onprem" {
  description              = "Allow onprem network to reach the cluster endpoint"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.onprem.id
  cidr_blocks              = [var.onprem_cidr]
  to_port                  = 443
  type                     = "ingress"
}

# Control Plane
resource "aws_eks_cluster" "controlplane" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.controlplane_role.arn

  vpc_config {
    security_group_ids = [aws_security_group.onprem.id]
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.controlplane_role_eksclusterpolicy,
    aws_security_group_rule.onprem,
  ]
}

