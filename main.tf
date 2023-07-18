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
#the data "aws_vpc" is been  replaced by the VPC module to scale)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-12b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}


resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

  subnet_id              = module.blog_vpc.public_subnets[0]
  vpc_security_group_ids = [module.blog_sg.security_group_id]

  tags = {
    Name = "learning_Terraform"
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "blog-alb"

  load_balancer_type = "application"

  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]

  target_groups = [
    {
      name_prefix      = "blog-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        my_target = {
          target_id = aws_instance.blog.id
          port = 80
        }
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "dev"
  }
}


module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name = "blog"
  vpc_id = module.blog_vpc.vpc_id 
  ingress_rules = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

#resource "aws_security_group" "blog" {
  #name = "blog"
  #description = " allow http and https in and allow everything out "
  #vpc_id = data.aws_vpc.default.id
#}
#resource "aws_security_group_rule" "blog_http_in" {
  #type        = "ingress"
  #from_port   = 80
  #to_port     = 80
  #protocol    = "tcp"
  #cidr_blocks = ["0.0.0.0/0"]
 # security_group_id = aws_security_group.blog.id
#}
#resource "aws_security_group_rule" "blog_https_in" {
  #type        = "ingress"
  #from_port   = 443
  #to_port     = 443
  #protocol    = "tcp"
  #cidr_blocks = ["0.0.0.0/0"]
  #security_group_id = aws_security_group.blog.id
#}
#resource "aws_security_group_rule" "blog_everything_out" {
  #type        = "egress"
  #from_port   = 0
  #to_port     = 0
  #protocol    = "-1"
  #cidr_blocks = ["0.0.0.0/0"]
  #security_group_id = aws_security_group.blog.id
#}

