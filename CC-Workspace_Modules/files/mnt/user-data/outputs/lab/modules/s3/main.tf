# ============================================================
#  modules/s3/main.tf
#  One S3 bucket per environment, each with versioning,
#  encryption, and public access block enabled.
#  Bucket name pattern: sk-tf-dev-app-bucket
#                       sk-tf-staging-app-bucket
#                       sk-tf-prod-app-bucket
# ============================================================

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = { Name = var.bucket_name }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
