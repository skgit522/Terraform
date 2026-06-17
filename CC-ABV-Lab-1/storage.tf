# ============================================================
#  storage.tf
#  S3 bucket for application use (assets, logs, uploads, etc.)
#  Includes versioning and encryption — both are expected
#  in any production-grade setup.
# ============================================================

# ── S3 Bucket ────────────────────────────────────────────────
# Object storage for application files. Name must be globally
# unique across all AWS accounts — include your project and a
# unique suffix (account ID, date, etc.) to avoid conflicts.
resource "aws_s3_bucket" "main" {
  bucket = var.s3_bucket_name

  tags = {
    Name = var.s3_bucket_name
  }
}

# ── Versioning ───────────────────────────────────────────────
# Keeps previous versions of every object. Lets you recover
# files that were overwritten or deleted accidentally.
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Server-Side Encryption ───────────────────────────────────
# Encrypts all objects at rest using AWS-managed keys (SSE-S3).
# Zero cost, zero performance impact — always enable this.
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ── Block Public Access ───────────────────────────────────────
# Prevents the bucket from ever being made public, even if someone
# accidentally adds a public bucket policy later.
# Remove only if this bucket intentionally hosts public static files.
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
