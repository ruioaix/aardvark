# Aardvark: Provisioning EKS with Terraform

The name is aardvark.

I am using aardvark to create Kubernetes 1.20(verified), 1.21(verified), 1.22(verified) on EKS.

Works very well, verified hundreds of times of `terraform apply` and `terraform destory`.

## How to use it

First, have aws cli configured correctly, terraform will use aws config&credential.

### If you use terrafrom cloud

Ingore `s3backend` directory and `cd eks`.

* changes `default.auto.tfvars` accordintly.
* changes `terraform.backend` part in `providers.tf` to use `remote` instead of `s3`.

### If you use s3 backend

first `cd s3backend`

* changes `default.auto.tfvars` accordintly.
    * `var.cluster_name` is used as the name of both s3 bucket and dynamodb table.
* then `terraform init && terraform apply -auto-approve`.

second `cd eks`

* changes `default.auto.tfvars` accordintly.
* changes `providers.tf` to use the correct s3 bucket and dynamodb table.
* then `terraform init && terraform apply -auto-approve`.

## Some implementation details

### eks iam user/group/role and k8s rbac

In `eks/users.tf`, I bind the aws role `k8smaster` with k8s `system:masters`.

If you want all the IAM users belonging a IAM group to have `system:masters` permissions, just create a IAM group and bind the group with aws role `k8smaster`.

Or if you want a specific IAM user to have `system:masters` permissions, just add the user to `"mapUsers"` part.

### vpc is not configured and locally I am in a on-prem net

In my current environment, aws vpc and on-prem are preconfigured.
