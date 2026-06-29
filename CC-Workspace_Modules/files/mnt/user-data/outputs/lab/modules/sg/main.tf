# ============================================================
#  modules/sg/main.tf
#  Security group module. Receives vpc_id from the vpc module.
#  Ingress/egress rules are defined as separate resources so
#  they can be modified without recreating the security group
#  (which would cause downtime if EC2 instances use it).
# ============================================================

resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Allow HTTP and SSH inbound, all outbound"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.project_name}-${var.environment}-web-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH — restrict to your IP in prod"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
