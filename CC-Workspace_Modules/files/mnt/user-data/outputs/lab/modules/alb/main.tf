# ============================================================
#  modules/alb/main.tf
#  Creates ALB, target group, health check, listener,
#  and dynamically attaches all EC2 instances.
#
#  The for_each on target group attachments is the key pattern:
#  it iterates over the instance_ids list from the ec2 module,
#  creating one attachment per instance regardless of how many
#  instances exist. Works for 1 instance (dev) or 4 (prod).
# ============================================================

resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = { Name = "${var.project_name}-${var.environment}-alb" }
}

resource "aws_lb_target_group" "this" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }

  tags = { Name = "${var.project_name}-${var.environment}-tg" }
}

# Dynamically attaches every instance from the EC2 module.
# for_each converts the list to a map keyed by instance ID.
# If instance_count changes, Terraform adds/removes attachments.
resource "aws_lb_target_group_attachment" "this" {
  for_each = toset(var.instance_ids)

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = each.value
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
