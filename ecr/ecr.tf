
terraform {
    required_version = ">=1.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.26.0"
        }
    }
}

provider "aws" {}

# aws ecr 생성
# resource "aws_ecr_repository" "demo-repository" {
#     name = "demo-a"
# }

# ecr 설정 변경
# immutable / kms 키 생성 / 
# resource "aws_ecr_repository" "demo-repository" {
#     name = "demo-a"
#     image_tag_mutability = "IMMUTABLE"

#     encryption_configuration {
#       encryption_type = "KMS"
#     }

#     image_scanning_configuration {
#       scan_on_push = true
#     }
# }

/* 위와 같은 설정의 repository를 여러개 생성할 때 
locals : Terraform 구성 파일 내에서 변수를 정의

toset() : 리스트를 집합으로 변환하여 중복을 제거, 순서가 보장X
for_each :  집합(set)이나 맵(map)과 함께 사용. 이 코드에서는 집합을 사용하여 각 요소에 대해 리소스를 생성.
each.key : each.key는 현재 반복 중인 요소의 키를 나타냄. 이 경우, demo-repositories 집합의 각 요소가 each.key로 사용
each.value :  맵(map)에서만 사용, 집합(set)에서는 사용되지 않음.
*/

locals {
  demo-repositories = [
    "demo-a",
    "demo-b",
    "demo-c",
    "demo-d"
  ]
}

resource "aws_ecr_repository" "demo-repository" {
    for_each = toset(local.demo-repositories)
    name = each.key
    image_tag_mutability = "IMMUTABLE"

    encryption_configuration {
      encryption_type = "KMS"
    }

    image_scanning_configuration {
      scan_on_push = true
    }
}