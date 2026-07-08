resource "aws_wafv2_web_acl" "this" {
  name  = "${var.name}-web-acl"
  scope = "CLOUDFRONT"
  default_action { allow {} }
  visibility_config { cloudwatch_metrics_enabled = true metric_name = "${var.name}-waf" sampled_requests_enabled = true }
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action { none {} }
    statement { managed_rule_group_statement { name = "AWSManagedRulesCommonRuleSet" vendor_name = "AWS" } }
    visibility_config { cloudwatch_metrics_enabled = true metric_name = "common" sampled_requests_enabled = true }
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  aliases             = [var.domain_name]
  web_acl_id          = aws_wafv2_web_acl.this.arn
  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values { query_string = true cookies { forward = "all" } }
  }
  origin {
    domain_name = var.alb_dns_name
    origin_id   = "alb-origin"
    custom_origin_config { http_port = 80 https_port = 443 origin_protocol_policy = "http-only" origin_ssl_protocols = ["TLSv1.2"] }
  }
  restrictions { geo_restriction { restriction_type = "none" } }
  viewer_certificate { acm_certificate_arn = var.acm_certificate_arn ssl_support_method = "sni-only" minimum_protocol_version = "TLSv1.2_2021" }
}

resource "aws_route53_record" "app" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  alias { name = aws_cloudfront_distribution.this.domain_name zone_id = aws_cloudfront_distribution.this.hosted_zone_id evaluate_target_health = false }
}
