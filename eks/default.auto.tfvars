cluster_region  = "eu-central-1"
aws_account_id = "xxxxxxxxxxxx"
vpc_id      = "vpc-xxxxxxxx"
subnet_ids = [
  "subnet-xxxxxxxx",
  "subnet-xxxxxxxx",
  "subnet-xxxxxxxx",
]
onprem_cidr = "10.0.0.0/8"
k8s_master_role = "an_aws_role_name"
ec2_type = "t2.xlarge"

cluster_name = "just-a-long-enough-name-3422513"
cluster_version = "1.22"
eks_optimized_ami = "/aws/service/eks/optimized-ami/1.22/amazon-linux-2/recommended/image_id"
