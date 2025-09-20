terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "ec2" {
  ami = "ami-0d15ead583fbb2234"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "jellyfin-server"
  }
}

# EBS
resource "aws_ebs_volume" "media" {
  availability_zone = aws_instance.ec2.availability_zone
  size = 100
  type = "gp3"
  tags = {
    Name = "media-volume"
  }
}

resource "aws_volume_attachment" "media_attach" {
  device_name = "/dev/sdf"
  instance_id = aws_instance.ec2.id
  volume_id   = aws_ebs_volume.media.id
}

# Security group
resource "aws_security_group" "ssh" {
  name = "jellyfin-ssh-sg"
}

resource "aws_vpc_security_group_ingress_rule" "ssh_ingress" {
  security_group_id = aws_security_group.ssh.id
  description = "Allow SSH from my IP"

  ip_protocol = "tcp"
  cidr_ipv4   = "${var.my_ip}/32"
  from_port = 22
  to_port = 22
}

resource "aws_vpc_security_group_egress_rule" "ssh_egress" {
  security_group_id = aws_security_group.ssh.id
  description       = "Allow all outbound traffic"

  ip_protocol = "tcp"
  cidr_ipv4       = "0.0.0.0/0"
  from_port         = 0
  to_port           = 0
}