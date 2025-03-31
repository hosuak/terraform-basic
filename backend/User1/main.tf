
terraform {
  backend "s3" {
    bucket = "demo-terraform-state20250331201623550900000001"
    key    = "demo-terraform-state"
    region = "ap-northeast-2"
    dynamodb_table = "demo-terraform-lock"
  }
  required_version = ">=1.0"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "5.26.0"
    }
  }
}

resource "aws_vpc" "demo_vpc" {
    cidr_block = "10.0.0.0/16"
}