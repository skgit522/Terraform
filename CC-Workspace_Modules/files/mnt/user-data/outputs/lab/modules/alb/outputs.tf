# modules/alb/outputs.tf
output "alb_dns_name" {
  description = "Public DNS — paste into browser to reach the app"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}
