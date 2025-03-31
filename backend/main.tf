
# https://developer.hashicorp.com/terraform/language/backend/s3

terraform {
  required_version = ">=1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.26.0"
    }
  }
}

provider "aws" {}

# terraform state 파일을 aws s3에 저장
/*
Warning! It is highly recommended that you enable Bucket Versioning on the S3 bucket to allow for state recovery in the case of accidental deletions and human error. 
*/

# s3 생성
resource "aws_s3_bucket" "demo_bucket" {
  bucket_prefix = "demo-terraform-state"
  force_destroy = true
}

# S3 버킷에 버전 관리 활성화
# 버전 관리는 state 파일 복구를 위해 권장
resource "aws_s3_bucket_versioning" "demo_versioning" {
  bucket = aws_s3_bucket.demo_bucket.id # 버전 관리를 적용할 S3 버킷 ID

  versioning_configuration {
    status = "Enabled" # 버전 관리 활성화
    }
}


# Terraform state 잠금을 위한 DynamoDB 테이블 생성
# 원격 저장소 사용 시, 동시 작업 방지를 위해 state 잠금(locking) 메커니즘 필요
resource "aws_dynamodb_table" "demo_table" {
  name         = "demo-terraform-lock" # DynamoDB 테이블 이름
  hash_key     = "LockID"              # 해시 키 정의 (잠금 식별자)
  billing_mode = "PAY_PER_REQUEST"     # 사용량 기반 과금 모드

  # 테이블 속성 정의 (LockID는 문자열 타입)
  attribute {
    name = "LockID"
    type = "S" # 문자열(String) 타입
    }
}

