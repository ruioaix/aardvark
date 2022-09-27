data "aws_iam_policy_document" "autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.theprovider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.theprovider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.autoscaler_assume_role_policy.json
  name = "${var.cluster_name}-autoscaler-role"
}

resource "aws_iam_policy" "autoscaler" {
  name        = "${var.cluster_name}-AutoScalerPolicy"
  description = "Allows autoscaler to work"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": ["*"],
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.autoscaler.name
}

resource "helm_release" "autoscaler" {
  name       = "autoscaler"
  version    = "9.9.2"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"

  values = [ <<EOF
awsRegion: ${var.cluster_region}
autoDiscovery:
  clusterName: ${var.cluster_name}
  tags:
    - k8s.io/cluster-autoscaler/enabled
    - k8s.io/cluster-autoscaler/${var.cluster_name}
rbac:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: ${aws_iam_role.autoscaler.arn}
    name: cluster-autoscaler
EOF
  ]

  depends_on = [
    aws_iam_role_policy_attachment.autoscaler,
    aws_eks_cluster.controlplane,
    aws_eks_node_group.first,
    aws_eks_addon.coredns,
    aws_eks_addon.csi,
    kubernetes_config_map.aws_auth,
  ]
}
