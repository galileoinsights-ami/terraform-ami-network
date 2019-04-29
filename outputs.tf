output "vpc_id" {
  description = "The ID of the VPC"
  value = "${module.vpc.vpc_id}"
}

output "public_subnets" {
  description = "List of all Public Subnets (DMZ)"
  value = "${module.vpc.public_subnets}"
}

output "private_subnets" {
  description = "List of all Private Subnets"
  value = "${module.vpc.private_subnets}"
}

output "database_subnets" {
  description = "List of all database Subnets"
  value = "${module.vpc.database_subnets}"
}

output "nat_public_ips" {
  description = "List of all NAT box Public IPs"
  value = "${aws_eip.nat.*.public_ip}"
}

output "default_security_group_id" {
  description = "ID of the Default AMI internal Security Group"
  value = "${aws_default_security_group.default_sg.id}"
}

output "web_security_group_id" {
  description = "ID of the Web Security Group"
  value = "${aws_security_group.web_sg.id}"
}

output "bastion_security_group_id" {
  description = "ID of the Web Security Group"
  value = "${aws_security_group.bastion_sg.id}"
}