
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

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"
  name    = "demo-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  # nat-gw 1대 생성
  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_security_group" "demo-alb-sg" {
  name        = "demo-alb-sg"
  description = "demo-alb-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1 # 모든 프로토콜을 허용. -1 : TCP, UDP, ICMP 등 모든 프로토콜을 포함
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "demo-ec2-sg" {
  name        = "demo-ec2-sg"
  description = "demo-ec2-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.demo-alb-sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ex1 ) 하나의 인스턴스만 생성
# resource "aws_instance" "demo-ec2" {
#   ami                    = data.aws_ami.ubuntu.id
#   instance_type          = "t2.micro"
#   subnet_id              = module.vpc.private_subnets[0]
#   vpc_security_group_ids = [aws_security_group.demo-ec2-sg.id]

#   user_data = <<-EOF
#             #!/bin/bash
#             apt update
#             apt install -y nginx
#             systemctl start nginx
#             systemctl enable nginx
#             EOF
# }

# for_each 사용해 두 개의 인스턴스 생성
resource "aws_instance" "demo-ec2" {
  for_each = toset(["1", "2"])
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"

  /* 
    각 인스턴스를 서로 다른 서브넷에 배치 
    고가용성을 위해 az 두개 사용할 수 있도록 함. 
    `tonumber(each.key) % 2`를 사용하여 서브넷을 번갈아 선택
  */
  subnet_id              = module.vpc.private_subnets[tonumber(each.key) % 2]
  vpc_security_group_ids = [aws_security_group.demo-ec2-sg.id]

  user_data = <<-EOF
            #!/bin/bash
            apt update
            apt install -y nginx
            systemctl start nginx
            systemctl enable nginx
            EOF
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }
}

resource "aws_lb_target_group" "demo-tg-80" {
  name     = "demo-tg-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}


/*
    하나의 EC2 인스턴스를 타겟 그룹에 연결
    depends_on - ec2, lb 생성 후 리소스 생성되도록 의존성 설정    
*/
# resource "aws_lb_target_group_attachment" "demo-alb_tg_attach" {
#   target_group_arn = aws_lb_target_group.demo-tg-80.arn
#   target_id        = aws_instance.demo-ec2.id
#   port             = 80
#   depends_on       = [aws_instance.demo-ec2, aws_lb_target_group.demo-tg-80] 
# }


# for_each를 사용하여 모든 EC2 인스턴스를 타겟 그룹에 연결
resource "aws_lb_target_group_attachment" "demo-alb_tg_attach" {
  for_each = aws_instance.demo-ec2
  target_group_arn = aws_lb_target_group.demo-tg-80.arn
  target_id        = each.value.id
  port             = 80
  depends_on       = [aws_instance.demo-ec2, aws_lb_target_group.demo-tg-80]
  }


resource "aws_lb" "demo_alb" {
  name     = "demo-alb"
  internal = false # 외부 접근 가능

  load_balancer_type = "application"
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  security_groups    = [aws_security_group.demo-alb-sg.id]
}

/*
    80 port로 들어오는 HTTP요청을 처리 : target group으로 갈 수 있도록 연결
    기본동작 정의 : 요청이 demo_listener_rule과 일치하지 않으면 403 forbidden 응답
*/
resource "aws_lb_listener" "demo_listener" {
    load_balancer_arn = aws_lb.demo_alb.arn
    port = 80
    protocol = "HTTP"


    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            status_code = 403
      }
    }
}

/*
    priority - 규칙의 우선순위 설정 : 1이 가장 높음 (숫자 낮을 수록 높은 우선순위)
    action - 요청 처리 동작 : 요청을 타겟 그룹으로 전달
    condition - 요청 필터링 조건 
    condition.path_pattern 조건 : 요청의 경로를 기반으로 필터링- 모든 경로에 대해 일치하도록 설정.  
*/

resource "aws_lb_listener_rule" "demo_listener_rule_http" {
    listener_arn = aws_lb_listener.demo_listener.arn
    priority = 1                
    

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.demo-tg-80.arn
    }
    
    condition {
      path_pattern {
        values = ["*"]
      }
    }
}

output "aws_lb" {
  value = aws_lb.demo_alb.dns_name
}
