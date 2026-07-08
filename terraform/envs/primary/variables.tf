variable "name" { type = string }
variable "primary_region" { type = string  default = "us-east-1" }
variable "dr_region" { type = string default = "us-west-2" }
variable "primary_azs" { type = list(string) default = ["us-east-1a", "us-east-1b"] }
variable "instance_type" { type = string default = "t3.micro" }
variable "ami_id" { type = string }
variable "db_instance_class" { type = string default = "db.t3.micro" }
variable "route53_zone_id" { type = string }
variable "domain_name" { type = string }
variable "acm_certificate_arn_us_east_1" { type = string }
