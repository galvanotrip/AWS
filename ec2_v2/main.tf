terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.12.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Network part
resource "aws_vpc" "terraform_vpc" {
#  cidr_block = "10.0.0.0/16"
  cidr_block = "10.0.0.0/16"
  tags       = {
    Name      = "terrafrom_vpc_test"
    Terraform = "true"
  }
}

resource "aws_subnet" "terraform_subnet_1" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags              = {
    Name      = "terrafrom_subnet_us-east-1a"
    Terraform = "true"
  }
}

resource "aws_subnet" "terraform_subnet_2" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags              = {
    Name      = "terrafrom_subnet_us-east-1a"
    Terraform = "true"
  }
}
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags   = {
    Name = "terraform-igw-test"
  }
}

#resource "aws_vpc_attachment" "attach_igw_to_vpc" {
#  vpc_id              = aws_vpc.terraform_vpc.id
#  internet_gateway_id = aws_internet_gateway.internet_gw.id
#}

resource "aws_route" "route" {
  route_table_id              = aws_vpc.terraform_vpc.main_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.internet_gw.id
}

#resource "aws_route_table" "route_table" {
#  vpc_id = aws_vpc.terraform_vpc.id
#
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.internet_gw.id
#  }
#  tags = {Terraform = "true"}
#}

#resource "aws_route" "attach_routing_table_to_vpc" {
#  route_table_id         = aws_route_table.route_table.id
#  destination_cidr_block = "0.0.0.0/0"
#  gateway_id             = aws_internet_gateway.internet_gw.id
#}


# Security part
resource "aws_security_group" "SSH_sec_group_terraform" {
  name_prefix = "security-group-ssh-terraform"
  vpc_id = aws_vpc.terraform_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "public_access_terraform" {
  #  name_prefix = "https & http" # conflicts with a name.
  name        = "public_access_terraform"
  description = "https & http"
  vpc_id = aws_vpc.terraform_vpc.id
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS2"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# create ec2 instance
resource "aws_instance" "ec2_AWS_ami_instance" {
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  ami                         = var.ami_id
  availability_zone           = "us-east-1a"
  subnet_id = aws_subnet.terraform_subnet_1.id
  #  vpc_id = var.vpc_id
  #  subnet_id     = var.vpc_id
  associate_public_ip_address = "true"
  tags                        = { Terraform = "true", Name = "Terraform-test" }
  vpc_security_group_ids      = [
    aws_security_group.SSH_sec_group_terraform.id, aws_security_group.public_access_terraform.id
  ]
}

# create elastic ip and assign it to the created vm
resource "aws_eip" "eip_terraform" {
  domain = "standard"
  tags   = {
    Name = "elastic_ip_terraform_check"
  }
}

resource "aws_eip_association" "associate_with_ec2_AWS_ami_instance" {
  instance_id   = aws_instance.ec2_AWS_ami_instance.id
  allocation_id = aws_eip.eip_terraform.id
}

resource "local_file" "ansible_host" {
  content  = aws_instance.ec2_AWS_ami_instance.public_ip
  filename = "${path.module}/host"
}


