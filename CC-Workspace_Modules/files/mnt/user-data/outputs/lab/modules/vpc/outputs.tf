# modules/vpc/outputs.tf
# These outputs are consumed by sg, ec2, and alb modules.
# Without these, other modules would have no way to know
# which VPC and subnets were just created.

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public_2.id
}
