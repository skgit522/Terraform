# modules/ec2/outputs.tf
# instance_ids is a list — the alb module needs this to
# attach every instance to the target group dynamically,
# regardless of how many instances were created.

output "instance_ids" {
  description = "List of all EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "instance_public_ips" {
  description = "List of public IPs for SSH access"
  value       = aws_instance.web[*].public_ip
}
