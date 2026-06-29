# ============================================================
#  versions.tf
#  Locks Terraform CLI and AWS provider versions.
#  The S3 backend block stores each workspace's state file
#  separately under env:/<workspace>/terraform.tfstate
# ============================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── Remote state backend ──────────────────────────────────
  # Terraform workspaces automatically prefix state keys with
  # env:/<workspace_name>/ so each workspace gets its own file:
  #   env:/dev/terraform.tfstate
  #   env:/staging/terraform.tfstate
  #   env:/prod/terraform.tfstate
  # DynamoDB table provides locking — prevents two people from
  # running terraform apply at the same time on the same env.
  backend "s3" {
    bucket         = "sk-tf-state-bucket"       # created in Step 5
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "sk-tf-state-lock"         # created in Step 5
    encrypt        = true
  }
}
