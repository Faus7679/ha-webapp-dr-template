# Warm-standby DR environment. Deploy the same modules with DR CIDR ranges and lower ASG desired capacity.
# Promote RDS replica or restore latest AWS Backup/Snapshot during failover.
module "network" {
  source              = "../../modules/network"
  name                = "${var.name}-dr"
  vpc_cidr            = "10.1.0.0/16"
  public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  app_subnet_cidrs    = ["10.1.10.0/24", "10.1.20.0/24"]
  db_subnet_cidrs     = ["10.1.30.0/24", "10.1.31.0/24"]
  availability_zones  = var.dr_azs
}
