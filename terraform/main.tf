terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group
resource "aws_security_group" "statuspulse_sg" {
  name        = "statuspulse-sg"
  description = "Security group for StatusPulse server"

  # Custom SSH port
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Custom SSH"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "statuspulse-sg"
  }
}

# EC2 Instance
resource "aws_instance" "statuspulse" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.statuspulse_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    domain_name = var.domain_name
    admin_email = var.admin_email
  })

  tags = {
    Name = "statuspulse-server"
  }
}

output "public_ip" {
  value       = aws_instance.statuspulse.public_ip
  description = "Public IP of the StatusPulse server"
}

output "public_dns" {
  value       = aws_instance.statuspulse.public_dns
  description = "Public DNS of the StatusPulse server"
}
