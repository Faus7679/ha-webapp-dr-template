terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

module "network" {
  source              = "../../modules/network"
  name                = var.name
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  app_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
  db_subnet_cidrs     = ["10.0.30.0/24", "10.0.31.0/24"]
  availability_zones  = var.primary_azs
}

module "rds" {
  source             = "../../modules/rds"
  name               = var.name
  vpc_id             = module.network.vpc_id
  db_subnet_ids      = module.network.db_subnet_ids
  app_security_group = module.compute.app_security_group_id
  engine             = "mysql"
  instance_class     = var.db_instance_class
  multi_az           = true
  backup_retention   = 7
}

module "compute" {
  source             = "../../modules/compute"
  name               = var.name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  app_subnet_ids     = module.network.app_subnet_ids
  instance_type      = var.instance_type
  ami_id             = var.ami_id
  desired_capacity   = 2
  min_size           = 2
  max_size           = 6
}

module "s3_dr" {
  source     = "../../modules/s3-dr"
  providers  = { aws = aws, aws.dr = aws.dr }
  name       = var.name
  dr_region  = var.dr_region
}

module "cloudfront_waf" {
  source              = "../../modules/cloudfront-waf"
  name                = var.name
  alb_dns_name        = module.compute.alb_dns_name
  route53_zone_id     = var.route53_zone_id
  domain_name         = var.domain_name
  acm_certificate_arn = var.acm_certificate_arn_us_east_1
}

module "monitoring" {
  source        = "../../modules/monitoring"
  name          = var.name
  alb_arn_suffix = module.compute.alb_arn_suffix
  asg_name      = module.compute.asg_name
  rds_id        = module.rds.db_instance_id
}
