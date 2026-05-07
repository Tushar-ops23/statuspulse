variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "domain_name" {
  description = "Domain name for StatusPulse"
  type        = string
}

variable "admin_email" {
  description = "Email for TLS certificates"
  type        = string
}
