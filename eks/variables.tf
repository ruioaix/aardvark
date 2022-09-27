variable "cluster_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "onprem_cidr" {
  type = string
}

variable "eks_optimized_ami" {
  type = string
}

variable "ec2_type" {
  type = string
}

variable "k8s_master_role" {
  type = string
}
