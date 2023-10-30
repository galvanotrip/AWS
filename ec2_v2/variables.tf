variable aws_access_key {
  type        = string
  description = "aws access key"
}

variable aws_secret_key {
  type        = string
  description = "aws secret key"
}

variable ssh_key_name {
  type        = string
  description = "name for ssh pub file in aws"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "instance type/sizes/architecture"
}
variable "ami_id" {
  type        = string
  default     = "ami-08a52ddb321b32a8c"
  description = "ec2 image ID. default = Amazon Linux 2023 AMI 2023.1.20230809.0 x86_64 HVM kernel-6.1"
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
}

variable "security_group_id" {
  type = string
  description = "security group for network"
}
