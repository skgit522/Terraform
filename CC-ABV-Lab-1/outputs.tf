# ============================================================
#  outputs.tf
#  Collects all useful values produced after terraform apply.
#  These print to the terminal and can be consumed by other
#  Terraform projects via "terraform_remote_state" data source.
# ============================================================

# ── Networking ───────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_1_id" {
  description = "ID of public subnet 1 (AZ-1)"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "ID of public subnet 2 (AZ-2)"
  value       = aws_subnet.public_2.id
}

# ── Compute ──────────────────────────────────────────────────

output "instance_1_public_ip" {
  description = "Public IP of EC2 instance 1 — use for direct SSH access"
  value       = aws_instance.web_1.public_ip
}

output "instance_2_public_ip" {
  description = "Public IP of EC2 instance 2"
  value       = aws_instance.web_2.public_ip
}

# ── Load Balancer ─────────────────────────────────────────────

output "alb_dns_name" {
  description = "Public DNS name of the ALB — paste this into your browser"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the ALB — useful for WAF or Route53 alias records"
  value       = aws_lb.main.arn
}

# ── Storage ──────────────────────────────────────────────────

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket — use in IAM policies to grant EC2 access"
  value       = aws_s3_bucket.main.arn
}
