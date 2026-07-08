output "vpc_id" { value = module.network.vpc_id }
output "alb_dns_name" { value = module.compute.alb_dns_name }
output "cloudfront_domain" { value = module.cloudfront_waf.cloudfront_domain_name }
output "rds_endpoint" { value = module.rds.endpoint }
