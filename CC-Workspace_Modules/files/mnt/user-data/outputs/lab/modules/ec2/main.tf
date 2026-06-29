# ============================================================
#  modules/ec2/main.tf
#  Deploys count EC2 instances spread across both subnets.
#  count.index % length(subnet_ids) distributes instances:
#    instance 0 → subnet_ids[0]  (AZ-1)
#    instance 1 → subnet_ids[1]  (AZ-2)
#    instance 2 → subnet_ids[0]  (AZ-1 again)
#    instance 3 → subnet_ids[1]  (AZ-2 again)
#  This gives automatic multi-AZ distribution regardless of count.
# ============================================================

resource "aws_key_pair" "this" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "web" {
  count = var.instance_count

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.this.key_name

  # Bootstraps Apache on first boot.
  # The webpage shows environment name and instance number
  # so you can see the ALB alternating between instances.
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>${var.project_name} | ENV: ${var.environment} | Instance: ${count.index + 1}</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-web-${count.index + 1}"
  }
}
