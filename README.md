# Three-Tier Highly Available Web Application with Multi-Region DR

This template implements the architecture shown in the image: Route 53, AWS WAF, CloudFront, public/private subnets, ALB, Auto Scaling EC2 app tier, RDS MySQL Multi-AZ, S3 cross-region replication, Secrets Manager, KMS-ready encryption, CloudWatch alarms, and a warm-standby DR region.

## Architecture Summary

- **Route 53** provides DNS and failover routing.
- **AWS WAF** is attached to **CloudFront**, which is the correct global edge protection point for internet traffic.
- **CloudFront** serves as the global CDN and forwards dynamic traffic to the regional ALB.
- **Public subnets** host the ALB and NAT Gateways only.
- **Private app subnets** host EC2 instances in an Auto Scaling Group across two Availability Zones.
- **Private DB subnets** host Amazon RDS MySQL with Multi-AZ enabled.
- **NAT Gateways** allow private app and DB resources to reach the internet for updates without exposing them publicly.
- **S3 Cross-Region Replication** copies static assets/backups from the primary region to the DR region.
- **CloudWatch** monitors ALB 5xx errors and RDS CPU utilization.
- **Warm standby DR** keeps a reduced-capacity environment ready in `us-west-2`.

## Folder Structure

```text
terraform/
  envs/
    primary/        # Primary us-east-1 deployment
    dr/             # DR us-west-2 warm standby skeleton
  modules/
    network/        # VPC, subnets, IGW, NAT, route tables
    compute/        # ALB, target group, launch template, ASG
    rds/            # RDS MySQL, DB subnet group, DB security group, secret
    s3-dr/          # S3 primary/DR buckets and replication config
    cloudfront-waf/ # CloudFront distribution, WAF Web ACL, Route 53 alias
    monitoring/     # CloudWatch alarms
```

## Prerequisites

1. Terraform 1.6 or later.
2. AWS CLI configured with credentials that can create VPC, EC2, RDS, S3, IAM, WAF, CloudFront, Route 53, and CloudWatch resources.
3. A Route 53 hosted zone for your domain.
4. An ACM certificate in `us-east-1` for CloudFront.
5. A valid AMI ID for the EC2 app servers.

## Implementation Steps

### 1. Configure values

```bash
cd terraform/envs/primary
cp terraform.tfvars.example terraform.tfvars
```

Update:

```hcl
name = "three-tier-ha"
ami_id = "ami-xxxxxxxxxxxxxxxxx"
route53_zone_id = "Z123456789EXAMPLE"
domain_name = "app.example.com"
acm_certificate_arn_us_east_1 = "arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID"
```

### 2. Deploy primary region

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### 3. Deploy DR region

The `envs/dr` folder is a warm-standby starter. Expand it by calling the same compute and RDS modules with DR values, but use lower desired capacity until failover.

```bash
cd ../dr
terraform init
terraform plan
terraform apply
```

### 4. Configure database DR

For production, use one of these patterns:

- RDS cross-region read replica where supported.
- AWS Backup cross-region copy and restore.
- RDS snapshot copy automation.

During failover, promote the standby database or restore the latest backup, then update the DR application configuration to point to the promoted DB endpoint.

### 5. Configure Route 53 failover

Create Route 53 health checks for the CloudFront/ALB health endpoint. Configure a primary failover record pointing to the primary CloudFront distribution and a secondary failover record pointing to the DR distribution.

### 6. Validate the deployment

Run these checks:

```bash
curl -I https://app.example.com
curl https://app.example.com/health
```

Confirm:

- WAF is associated with CloudFront.
- ALB is in public subnets.
- EC2 instances are in private app subnets.
- RDS is in private DB subnets and only accepts traffic from the app security group.
- NAT Gateways exist in public subnets.
- CloudWatch alarms exist.
- S3 objects replicate to the DR bucket.

## Security Notes

- Avoid opening inbound SSH from the internet. Use AWS Systems Manager Session Manager instead.
- Replace broad ALB inbound rules with CloudFront managed prefix lists when possible.
- Enable KMS encryption for S3, EBS, RDS, Secrets Manager, and backups.
- Enable AWS Config, GuardDuty, Security Hub, CloudTrail, and VPC Flow Logs for production.
- Store database credentials in Secrets Manager and rotate them.

## Failover Flow

1. Route 53 health checks detect primary application failure.
2. DNS failover sends users to the DR CloudFront distribution or DR ALB.
3. DR app tier scales up if warm standby capacity is lower.
4. DR database is promoted or restored from the latest replicated backup.
5. Application secrets/configuration are updated to use DR endpoints.
6. After primary recovery, perform controlled failback with data reconciliation.

## Production Improvements Needed

This is a strong starting template, but production deployment should add:

- Remote Terraform backend with S3 and DynamoDB state locking.
- Separate AWS accounts for dev, staging, prod, and DR.
- CI/CD pipeline for Terraform plan/apply.
- HTTPS listener on ALB with ACM certificate.
- CloudFront origin access controls for S3 if static content is served directly.
- RDS parameter groups, enhanced monitoring, Performance Insights, and read replicas.
- Auto Scaling target tracking policies.
- Centralized logging with CloudWatch Logs, OpenSearch, or a SIEM.
- Backup vault lock and tested restore runbooks.

## Caution

The template creates billable AWS resources, including NAT Gateways, RDS, ALB, CloudFront, and WAF. Review costs before applying in a real AWS account.
