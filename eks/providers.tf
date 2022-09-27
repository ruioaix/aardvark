terraform {
  backend "s3" {
    bucket         = "just-a-long-enough-name-3422513"
    key            = "state/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "just-a-long-enough-name-3422513"
  }
  #backend "remote" {
  #  organization = "ifdefme"
  #  workspaces {
  #    name = "aardvark"
  #  }
  #}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0.0, < 2.0.0"
}

provider "aws" {
  region = var.cluster_region
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      ClusterName = var.cluster_name
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.controlplane.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.controlplane.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.controlplane.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.controlplane.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}
