# ============================================================
#  variables.tf
#  Declares every input variable the project accepts.
#  Actual values come from terraform.tfvars (or -var flags in CI).
#  Rule: declare here, assign in tfvars — never hardcode values
#        in resource files.
# ============================================================

# ── Project-wide ─────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region where all resources will be created"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Short name for the project — used in resource names and tags"
  type        = string
  default     = "sk-tf"
}

variable "environment" {
  description = "Deployment environment: dev, staging, or prod"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

# ── Networking ───────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_1_cidr" {
  description = "CIDR block for public subnet 1 (must be within vpc_cidr)"
  type        = string
  default     = "10.1.0.0/24"
}

variable "subnet_2_cidr" {
  description = "CIDR block for public subnet 2 (must be within vpc_cidr)"
  type        = string
  default     = "10.1.1.0/24"
}

variable "az_1" {
  description = "Availability zone for subnet 1"
  type        = string
  default     = "ap-south-1a"
}

variable "az_2" {
  description = "Availability zone for subnet 2"
  type        = string
  default     = "ap-south-1b"
}

# ── Compute ──────────────────────────────────────────────────

variable "ami_id" {
  description = "AMI ID for EC2 instances (region-specific)"
  type        = string
  default     = "ami-05d2d839d4f73aafb"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.nano"
}

variable "key_name" {
  description = "Name to assign to the AWS key pair"
  type        = string
  default     = "tf-instance-key"
}

variable "public_key_path" {
  description = "Local path to the SSH public key file"
  type        = string
  #default     = "~/.ssh/id_rsa.pub"
  default = "./id_rsa.pub"
}

# ── Storage ──────────────────────────────────────────────────

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name (no underscores, lowercase only)"
  type        = string
  # No default — this must be unique globally. Force the user to set it.
}
