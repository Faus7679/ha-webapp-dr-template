variable "name" { type = string default = "three-tier-ha" }
variable "dr_azs" { type = list(string) default = ["us-west-2a", "us-west-2b"] }
