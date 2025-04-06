
terraform {
  required_version = ">=1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.26.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.24.0"
    }
  }
}

provider "aws" {}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

module "demo_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"
  name    = "demo-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  /* 
    eks에서 loadbalancer를 사용하기 위해 tag 추가
    [public subnet] "kubernetes.io/role/elb"=1
    [private subnet] "kubernetes.io/role/internal-elb"=1
    */
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

locals {
  cluster_name    = "demo-cluster"
  cluster_version = "1.30"
}

data "aws_ami" "demo_eks_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.cluster_version}-v*"]
  }
}

/*
# [주의] AWS Provider 5.26.0에서만 호환되는 EKS 모듈 v19.x 사용
# - v20.x는 >=5.34.0 필요 
참고: https://github.com/terraform-aws-modules/terraform-aws-eks
      https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/docs/UPGRADE-20.0.md
*/
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.21.0"
  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_encryption_config = {}

  /*
│ Warning: Argument is deprecated
│ 
│   with module.eks.aws_eks_addon.this["coredns"],
│   on .terraform/modules/eks/main.tf line 400, in resource "aws_eks_addon" "this":
│  400:   resolve_conflicts        = try(each.value.resolve_conflicts, "OVERWRITE")
│ 
│ The "resolve_conflicts" attribute can't be set to "PRESERVE" on initial resource creation. Use "resolve_conflicts_on_create"
│ and/or "resolve_conflicts_on_update" instead
│ 
│ (and 2 more similar warnings elsewhere)
*/
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = module.demo_vpc.vpc_id
  subnet_ids = module.demo_vpc.private_subnets


  /*
  - manage_aws_auth_configmap = true 설정 시 Terraform이 aws-auth ConfigMap을 관리하려 시도
  - Kubernetes provider가 EKS 클러스터와 통신할 수 있는 인증 정보가 없어 발생하는 연결 오류
│ Error: Have got the following error while validating the existence of the ConfigMap "aws-auth": Get "http://localhost/api/v1/namespaces/kube-system/configmaps/aws-auth": dial tcp 127.0.0.1:80: connect: connection refused
│ 
│   with module.eks.kubernetes_config_map_v1_data.aws_auth[0],
│   on .terraform/modules/eks/main.tf line 562, in resource "kubernetes_config_map_v1_data" "aws_auth":
│  562: resource "kubernetes_config_map_v1_data" "aws_auth" {

  kubernetes provider 설정
  */
  manage_aws_auth_configmap = true

  eks_managed_node_groups = {
    demo = {
      name            = "demo-ng"
      use_name_prefix = true

      subnet_ids = module.demo_vpc.private_subnets

      max_size     = 2
      min_size     = 1
      desired_size = 1

      ami_id                     = data.aws_ami.demo_eks_ami.id
      enable_bootstrap_user_data = true

      capacity_type  = "ON_DEMAND"
      instance_types = ["t3.medium"]

      create_iam_role = true
      iam_role_name   = "demo-ng-role"
      # iam role에 hash 값 붙여서 role 중복되지 않도록 함.
      iam_role_use_name_prefix = true

      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }
}