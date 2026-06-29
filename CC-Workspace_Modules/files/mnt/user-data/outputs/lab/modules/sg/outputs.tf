# modules/sg/outputs.tf
output "web_sg_id" {
  description = "Security group ID consumed by ec2 and alb modules"
  value       = aws_security_group.web.id
}
