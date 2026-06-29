# ============================================================
#  outputs.tf  — ROOT
#  Surfaces the most useful values after apply.
#  terraform.workspace in the description tells you which
#  environment these values belong to.
# ============================================================

output "active_workspace" {
  description = "Currently active workspace (environment)"
  value       = terraform.workspace
}

output "vpc_id" {
  description = "VPC ID for this environment"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Paste this into your browser to reach the app"
  value       = module.alb.alb_dns_name
}

output "instance_ids" {
  description = "List of EC2 instance IDs in this environment"
  value       = module.ec2.instance_ids
}

output "instance_public_ips" {
  description = "Public IPs for direct SSH access"
  value       = module.ec2.instance_public_ips
}

output "s3_bucket_name" {
  description = "Application S3 bucket for this environment"
  value       = module.s3.bucket_name
}
