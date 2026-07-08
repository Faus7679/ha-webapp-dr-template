provider "aws" { alias = "dr" }

resource "aws_s3_bucket" "primary" { bucket = "${var.name}-assets-primary" }
resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration { status = "Enabled" }
}
resource "aws_s3_bucket" "dr" { provider = aws.dr bucket = "${var.name}-assets-dr" }
resource "aws_s3_bucket_versioning" "dr" {
  provider = aws.dr
  bucket = aws_s3_bucket.dr.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_iam_role" "replication" {
  name = "${var.name}-s3-replication-role"
  assume_role_policy = jsonencode({Version="2012-10-17",Statement=[{Effect="Allow",Principal={Service="s3.amazonaws.com"},Action="sts:AssumeRole"}]})
}

resource "aws_s3_bucket_replication_configuration" "this" {
  depends_on = [aws_s3_bucket_versioning.primary, aws_s3_bucket_versioning.dr]
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.primary.id
  rule { id = "replicate-to-dr" status = "Enabled" destination { bucket = aws_s3_bucket.dr.arn storage_class = "STANDARD" } }
}
