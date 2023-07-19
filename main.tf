data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

#data "aws_vpc" "default" {
#default = true
#}
# we are creating new VPC using a module so i deactivated the default VPC above 

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  #private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  #enable_nat_gateway = true
  #enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.blog_sg.security_group_id]
  #vpc_security_group_ids = [aws_security_group.blog.id]

  tags = {
    Name = "HelloWorld"
  }
}
module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  name = "blog_new"
  
  #vpc_id      = data.aws_vpc.default.id
  # the above line to use with the default VPC in line 17 and been replaced with the line below to be used with VPC module

  vpc_id      = module.vpc.vpc_id

  ingress_rules = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

}


#resource "aws_security_group" "blog" {
#  name        = "blog"
# description = "allow http and https in ,allow everything out"
#  vpc_id      =  module.vpc.vpc_id

#}
#resource "aws_security_group_rule" "blog_http_in" {
#  type        = "ingress"
#  from_port   = 80
#  to_port     = 80
# protocol    = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.blog.id
#}

#resource "aws_security_group_rule" "blog_https_in" {
#type        = "ingress"
#  from_port   = 443
#  to_port     = 443
#  protocol    = "tcp"
#  cidr_blocks = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.blog.id
#}

#resource "aws_security_group_rule" "blog_everything_out" {
#  type        = "egress"
#  from_port   = 0
#  to_port     = 0
#  protocol    = "-1"
#  cidr_blocks = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.blog.id
#}
