# OpenID Connect Provider
data "tls_certificate" "oidc" {
  url = aws_eks_cluster.controlplane.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "theprovider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.controlplane.identity[0].oidc[0].issuer

  depends_on = [
    aws_eks_cluster.controlplane,
  ]
}
