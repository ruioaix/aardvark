data "aws_iam_role" "k8smaster" {
  name = var.k8s_master_role
}

data "aws_caller_identity" "current" {}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    "mapRoles" = <<EOF
- rolearn: ${aws_iam_role.dataplane.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
- rolearn: ${data.aws_iam_role.k8smaster.arn}
  username: ${data.aws_iam_role.k8smaster.id}
  groups:
    - system:masters
EOF

    "mapUsers" = <<EOF
- userarn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/ifdefme
  username: ifdefme
  groups:
    - system:masters
EOF
  }
}
