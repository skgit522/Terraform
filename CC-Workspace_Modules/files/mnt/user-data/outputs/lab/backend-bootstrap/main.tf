# ============================================================
#  backend-bootstrap/main.tf
#  STEP 5 — Run this ONCE before your main project.
#  Creates the S3 bucket and DynamoDB table that store and
#  lock your Terraform state files for all workspaces.
#
#  Run:
#    cd backend-bootstrap
#    terraform init
#    terraform apply
#  Then go back to the root lab folder and run terraform init.
#
#  NEVER run terraform destroy on this — it will delete all
#  your state files and you'll lose track of your infra.
# ============================================================

provider "aws" {
  region  = "ap-south-1"
  profile = "sk-tf"
}

# ── State S3 Bucket ───────────────────────────────────────────
# This single bucket stores state files for ALL workspaces.
# Terraform workspaces automatically prefix the key:
#   env:/dev/terraform.tfstate
#   env:/staging/terraform.tfstate
#   env:/prod/terraform.tfstate
resource "aws_s3_bucket" "state" {
  bucket = "sk-tf-state-bucket"   # must be globally unique

  tags = {
    Name    = "sk-tf-state-bucket"
    Purpose = "Terraform remote state storage"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── DynamoDB State Lock Table ─────────────────────────────────
# Prevents two people running terraform apply simultaneously.
# If apply is running, the lock entry exists in this table.
# Second person gets: "Error: state is locked by <user>"
resource "aws_dynamodb_table" "state_lock" {
  name         = "sk-tf-state-lock"
  billing_mode = "PAY_PER_REQUEST"   # no capacity planning needed
  hash_key     = "LockID"            # Terraform expects exactly this key name

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "sk-tf-state-lock"
    Purpose = "Terraform state locking"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.state_lock.name
}
