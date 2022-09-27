terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
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
