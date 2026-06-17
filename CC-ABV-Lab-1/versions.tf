# ============================================================
#  versions.tf
#  Locks down the Terraform CLI version and AWS provider version.
#  This ensures every team member and CI pipeline uses the same
#  versions — preventing "works on my machine" drift.
# ============================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Allows 5.x but not 6.x (safe upgrades)
    }
  }

  # ── Remote State (recommended for teams) ──────────────────
  # Stores the terraform.tfstate file in S3 instead of locally.
  # Enables team collaboration — everyone reads/writes the same state.
  # DynamoDB table provides state locking (prevents simultaneous applies).
  # Uncomment and configure once you have the S3 bucket & DynamoDB table ready.

  # backend "s3" {
  #   bucket         = "my-company-terraform-state"
  #   key            = "projects/aws-infra/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}
