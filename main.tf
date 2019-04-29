# Backend Initialization using command line

terraform {
 backend "s3" {
   key = "network.tfstate"
 }
}

locals {

  ## Number ot NAT EIPs is determined by the number to NAT boxes being spun up.
  ## Two scenarios allowed: Single NAT box (dev) or 1 NAT box per AZ (Higher Environments)
  number_nat_eips = "${var.vpc["single_nat_gateway"] ? 1:lookup(var.vpc,"max_azs")}"
}

# Initializing the provider

# Following properties need to be set for this to work
# export AWS_ACCESS_KEY_ID="anaccesskey"
# export AWS_SECRET_ACCESS_KEY="asecretkey"
# export AWS_DEFAULT_REGION="us-west-2"
# terraform plan
provider "aws" {}


## Get all available AWS AZs
data "aws_availability_zones" "available" {
  state = "available"
}

## Reservice EIPs for NAT boxes
resource "aws_eip" "nat" {
  count = "${local.number_nat_eips}"
  vpc = true
  tags = "${var.default_aws_tags}"
}

## Building the VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.64.0"

  name = "${lookup(var.vpc,"name")}"
  cidr = "${lookup(var.vpc,"cidr")}"

  ## Select the first "max_azs" from the list all AZs
  azs             = "${slice(data.aws_availability_zones.available.names, 0, lookup(var.vpc,"max_azs"))}"
  private_subnets = "${split(",",var.vpc["private_subnets"])}"
  public_subnets  = "${split(",",var.vpc["public_subnets"])}"
  database_subnets  = "${split(",",var.vpc["database_subnets"])}"

  # Database subnet group to be created separately for better control
  create_database_subnet_group = false

  enable_nat_gateway = "${lookup(var.vpc,"enable_nat_gateway")}"
  single_nat_gateway = "${lookup(var.vpc,"single_nat_gateway")}"
  one_nat_gateway_per_az = "${lookup(var.vpc,"one_nat_gateway_per_az")}"

  reuse_nat_ips       = true
  external_nat_ip_ids = ["${aws_eip.nat.*.id}"]


  tags = "${var.default_aws_tags}"
}

## Creating the database subnet group to be used by RDS instances
resource "aws_db_subnet_group" "default" {
  name       = "default_db_subnet_group"
  subnet_ids = ["${module.vpc.database_subnets}"]

  tags = "${var.default_aws_tags}"
}

## Renaming the Default SG to with a good name
resource "aws_default_security_group" "default_sg" {
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "ami_default_sg"),var.default_aws_tags)}"
}


## Security group to be applied to all WEB Loadbalancers and API Gateways
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "All communication as HTTP(S) ports"
  vpc_id      = "${module.vpc.vpc_id}"

  ## HTTPS Port
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  ## HTTP Port
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "web_sg"),var.default_aws_tags)}"
}

## Security group to be applied to Bastion Hosts
resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "SG to be applied on all Bastion hosts"
  vpc_id      = "${module.vpc.vpc_id}"

  ## SSH Port
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # Ideally should be restricted to the organizaiotns internal CIDR blocs
    #cidr_blocks =
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }


  tags = "${merge(map("Name", "bastion_sg"),var.default_aws_tags)}"
}