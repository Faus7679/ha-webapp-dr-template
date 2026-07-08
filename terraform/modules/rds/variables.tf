variable "name" { type = string }
variable "vpc_id" { type = string }
variable "db_subnet_ids" { type = list(string) }
variable "app_security_group" { type = string }
variable "engine" { type = string }
variable "instance_class" { type = string }
variable "multi_az" { type = bool }
variable "backup_retention" { type = number }
