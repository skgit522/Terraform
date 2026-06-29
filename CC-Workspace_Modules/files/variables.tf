# ============================================================
#  variables.tf  — ROOT
#  Only declares variables that do NOT change per workspace.
#  Environment-specific sizing lives in locals{} in main.tf.
#  Actual values come from envs/dev.tfvars etc.
# ============================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name from ~/.aws/credentials"
  type        = string
  default     = "sk-tf"
}

variable "project_name" {
  description = "Short project identifier used in all resource names"
  type        = string
  default     = "sk-tf"
}

variable "az_1" {
  description = "First availability zone"
  type        = string
  default     = "ap-south-1a"
}

variable "az_2" {
  description = "Second availability zone"
  type        = string
  default     = "ap-south-1b"
}

variable "ami_id" {
  description = "EC2 AMI ID — Ubuntu 22.04 LTS for ap-south-1"
  type        = string
  default     = "ami-05d2d839d4f73aafb"
}

variable "public_key_path" {
  description = "Path to SSH public key on your local machine"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
