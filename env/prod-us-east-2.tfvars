# default AWS Tags
default_aws_tags = {
  Terraform = "true"
  Environment = "prod"
}

# Organization wide variables

organizaiton_wide_cidr = "10.0.0.0/8"

# VPC Variables

vpc = {
  "name" = "prod-ami-vpc"
  "cidr" = "10.0.0.0/16"
  "max_azs" = 3
  "enable_nat_gateway" = true

  # It is okay to set the following to true for lower environments
  "single_nat_gateway"  = false

  # Belwo must be true for production environments
  "one_nat_gateway_per_az" = true
  "private_subnets" = "10.0.0.0/24,10.0.1.0/24,10.0.2.0/24"
  "public_subnets" = "10.0.100.0/24,10.0.101.0/24,10.0.102.0/24"
  "database_subnets" = "10.0.110.0/24,10.0.111.0/24,10.0.112.0/24"
}