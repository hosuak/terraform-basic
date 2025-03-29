# terraform cli version 명시
# terraform 저장소 지정
terraform {
    required_version = ">=1.0"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "5.26.0"
        }
    }
}

# registry.terraform.io/providers/hashicorp/aws/latest/docs 참고
provider "aws" {}

# aws vpc 생성
resource "aws_vpc" "demo-vpc" {
    cidr_block = "10.0.0.0/16"
}