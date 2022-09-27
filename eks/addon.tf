# VPC CNI
data "aws_iam_policy_document" "vpc_cni_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.theprovider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.theprovider.arn]
      type        = "Federated"
    }
  }
}
resource "aws_iam_role" "vpc_cni" {
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role_policy.json
  name = "${var.cluster_name}-vpccni-role"
}
resource "aws_iam_role_policy_attachment" "vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni.name
}
resource "aws_eks_addon" "cni" {
  cluster_name             = aws_eks_cluster.controlplane.name
  addon_name               = "vpc-cni"
  addon_version            = "v1.11.0-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni.arn

  depends_on = [
    aws_eks_cluster.controlplane,
    aws_iam_openid_connect_provider.theprovider,
    aws_iam_role_policy_attachment.vpc_cni,
  ]
}

# CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name      = aws_eks_cluster.controlplane.name
  addon_name        = "coredns"
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.first,
  ]
}

# Kube Proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = aws_eks_cluster.controlplane.name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.controlplane,
  ]
}

# EBS CSI
data "aws_iam_policy_document" "ebs_csi_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.theprovider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.theprovider.arn]
      type        = "Federated"
    }
  }
}
resource "aws_iam_role" "ebs_csi" {
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role_policy.json
  name = "${var.cluster_name}-ebscsi-role"
}
resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}
resource "aws_eks_addon" "csi" {
  cluster_name             = aws_eks_cluster.controlplane.name
  addon_name               = "aws-ebs-csi-driver"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_cluster.controlplane,
    aws_iam_openid_connect_provider.theprovider,
    aws_iam_role_policy_attachment.ebs_csi,
    aws_eks_node_group.first,
  ]
}

