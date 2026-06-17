# ============================================================
#  main.tf
#  Only holds provider configuration.
#  In a well-structured project, main.tf is intentionally thin —
#  all resources live in their own dedicated files.
# ============================================================

provider "aws" {
  region  = var.aws_region
  profile = "sk-tf" # secret access key will be read from this profile

  # Applies these tags to every resource automatically.
  # Saves you from repeating tags on every resource block.
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
