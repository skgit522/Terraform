# ============================================================
#  loadbalancer.tf
#  Application Load Balancer, target group, listener, and
#  target group attachments for both EC2 instances.
#
#  References from vpc.tf:
#    aws_vpc.main.id
#    aws_subnet.public_1.id
#    aws_subnet.public_2.id
#  References from security_group.tf:
#    aws_security_group.web.id
#  References from compute.tf:
#    aws_instance.web_1.id
#    aws_instance.web_2.id
# ============================================================

# ── Application Load Balancer ────────────────────────────────
# The public-facing entry point. Distributes incoming HTTP requests
# across healthy EC2 instances in both AZs.
# "internal = false" means it gets a public DNS name and IP.
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  # Prevents accidental deletion via terraform destroy.
  # Set to false only when intentionally tearing down.
  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ── Target Group ─────────────────────────────────────────────
# Defines the pool of EC2 instances that receive traffic.
# The health check pings "/" every 30s — instances that fail
# 2 consecutive checks are pulled from rotation automatically.
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2     # Pass 2 checks in a row → healthy
    unhealthy_threshold = 2     # Fail 2 checks in a row → unhealthy
    interval            = 30    # Check every 30 seconds
    timeout             = 5     # Wait up to 5s for a response
    matcher             = "200" # Expect HTTP 200 to consider healthy
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# ── Target Group Attachments ─────────────────────────────────
# Registers each EC2 instance as a target.
# The ALB only sends traffic to instances that pass health checks.
resource "aws_lb_target_group_attachment" "web_1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_2.id
  port             = 80
}

# ── ALB Listener ─────────────────────────────────────────────
# Listens on port 80 and forwards every request to the target group.
# In production, add a port 443 HTTPS listener with an ACM certificate
# and redirect HTTP → HTTPS here.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
