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

# module 버전 지정 안해주면 에러 발생
module "demo_vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "5.4.0"
    name = "demo_vpc"
    cidr = "10.0.0.0/16"

    azs = ["ap-northeast-2a"]
    public_subnets = ["10.0.1.0/24"]

    enable_nat_gateway = false
}

resource "aws_security_group" "demo_sg" {
    name = "demo-sg"
    description = "demo-sg"
    vpc_id = module.demo_vpc.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    } 
}


module "demo_key_pair" {
  source = "terraform-aws-modules/key-pair/aws"
  version = "2.0.2"
  key_name = "demo-key-pair"
  create_private_key = true
}

resource "aws_instance" "demo_instance" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = module.demo_vpc.public_subnets[0]
  associate_public_ip_address = true
  
  key_name = module.demo_key_pair.key_pair_name
  vpc_security_group_ids = [aws_security_group.demo_sg.id]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}