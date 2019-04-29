variable "default_aws_tags" {
  description = "default aws tags"
  default = {}
}

variable "vpc" {
  type = "map"
  description = "Containst all the information of AMI VPC"
  default = {}
}
