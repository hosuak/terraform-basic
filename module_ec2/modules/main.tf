
resource "aws_security_group" "demo_sg" {
    name = "${var.prefix}-sg"
    description = "${var.prefix}-sg"
    vpc_id = var.vpc_id

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
  key_name = "${var.prefix}-key-pair"
  create_private_key = true
}

resource "aws_instance" "demo_instance" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = var.subnet_id
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
