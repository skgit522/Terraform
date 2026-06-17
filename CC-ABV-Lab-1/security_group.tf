# ============================================================
#  security_group.tf
#  Defines virtual firewalls (security groups) for the project.
#  Keeping SGs in their own file makes rule auditing easy —
#  security reviews only need to look at this one file.
#
#  References from vpc.tf:
#    aws_vpc.main.id
# ============================================================

# ── Web Security Group ───────────────────────────────────────
# Attached to both EC2 instances and the ALB.
# Allows inbound HTTP (public web traffic) and SSH (admin access).
# Allows all outbound (needed for yum/apt updates, API calls, etc.)
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP inbound and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# ── Ingress: HTTP ─────────────────────────────────────────────
# Separating rules from the SG block is best practice — it allows
# rules to be added/removed without recreating the security group,
# which would cause downtime.
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.web.id
  description       = "Allow HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── Ingress: SSH ──────────────────────────────────────────────
# WARNING: 0.0.0.0/0 is acceptable for learning.
# In production, replace with your office/VPN IP: "203.0.113.0/32"
# Better yet, remove SSH entirely and use AWS Systems Manager
# Session Manager — zero open ports, full audit trail.
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.web.id
  description       = "Allow SSH - restrict this to your IP in production"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── Egress: All traffic ───────────────────────────────────────
# Allows instances to reach the internet for package installs,
# AWS API calls, and outbound application traffic.
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
