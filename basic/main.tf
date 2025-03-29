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

output "vpc_id" {
    value = aws_vpc.demo-vpc.id
}

# # aws security group 생성
# resource "aws_security_group" "demo-sg" {
#     name = "demo-sg"
#     vpc_id = aws_vpc.demo-vpc.id  
#     description = "Demo security group"

#     ingress {
#         from_port = 22
#         to_port = 22
#         protocol = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }

#     egress {
#         from_port = 0
#         to_port = 0
#         protocol = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#     }
# }

# aws security group 리소스명 변경 - terraform mv 명령어 사용방법
# terraform의 리소스명을 demo-sg 에서 demo-sg-0로 변경할 때 terraform은 기존 리소스인 demo-sg를 삭제하고 demo-sg-0을 새로 생성함
#   - resource "aws_security_group" "demo-sg" /  + resource "aws_security_group" "demo-sg-0
# 이때 $ terraform state mv 명령어를 사용하면 
#   - Move "aws_security_group.demo-sg" to "aws_security_group.demo-sg-0" Successfully moved 1 object(s).
# terrraform plan 시 no change 가 뜨게 된다.
resource "aws_security_group" "demo-sg-0" {
    name = "demo-sg"
    vpc_id = aws_vpc.demo-vpc.id  
    description = "Demo security group"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
