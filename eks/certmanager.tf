resource "helm_release" "certmanager" {
  name       = "certmanager"
  version    = "v1.8.0"
  namespace  = "kube-system"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"

  values = [ <<EOF
installCRDs: true
EOF
  ]

  depends_on = [
    aws_eks_cluster.controlplane,
    aws_eks_node_group.first,
    aws_eks_addon.coredns,
    aws_eks_addon.csi,
    kubernetes_config_map.aws_auth,
  ]
}
