data "aws_ssm_parameter" "eks_optimized_ami" {
  name            = var.eks_optimized_ami
  with_decryption = false
}

resource "aws_launch_template" "dataplane" {
  name = "${var.cluster_name}-launch-template"
  image_id = data.aws_ssm_parameter.eks_optimized_ami.value
  instance_type = var.ec2_type
  vpc_security_group_ids = [aws_eks_cluster.controlplane.vpc_config[0].cluster_security_group_id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 128
      volume_type = "gp2"
    }
  }

  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex
/etc/eks/bootstrap.sh ${var.cluster_name}

--==MYBOUNDARY==--
EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.cluster_name}-worker"
    }
  }
}

resource "aws_iam_role" "dataplane" {
  name               = "${var.cluster_name}-dataplane-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.dataplane.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.dataplane.name
}

resource "aws_eks_node_group" "first" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.cluster_name}-node-group-first"
  node_role_arn   = aws_iam_role.dataplane.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 6
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    name = aws_launch_template.dataplane.name
    version = aws_launch_template.dataplane.latest_version
  }

  lifecycle {
    ignore_changes = [scaling_config.0.desired_size]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_eks_addon.cni,
    aws_eks_addon.kube_proxy,
  ]
}
