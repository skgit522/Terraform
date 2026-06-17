# ============================================================
#  compute.tf
#  EC2 instances and SSH key pair.
#
#  References from vpc.tf:
#    aws_subnet.public_1.id
#    aws_subnet.public_2.id
#  References from security_group.tf:
#    aws_security_group.web.id
# ============================================================

# ── SSH Key Pair ─────────────────────────────────────────────
# Uploads your local public key to AWS. The private key (id_rsa)
# stays on your machine and is never uploaded anywhere.
# Generate a key pair with: ssh-keygen -t rsa -b 4096
resource "aws_key_pair" "main" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)

  tags = {
    Name = var.key_name
  }
}

# ── EC2 Instance 1 ───────────────────────────────────────────
# Placed in public subnet 1 (AZ-1). Runs your application.
# The user_data block installs and starts a basic web server
# automatically on first boot — useful for ALB health checks.
resource "aws_instance" "web_1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name

  # Bootstraps the instance on first launch.
  # Installs httpd so the ALB health check on port 80 succeeds.
  user_data = <<-EOF
    #!/bin/bash
    # Update package index
    apt-get update -y
    apt-get install -y apache2
  # Start and enable apache2 on boot#
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Hello from Instance 1 - AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.project_name}-web-instance-1"
    AZ   = var.az_1
  }
}

# ── EC2 Instance 2 ───────────────────────────────────────────
# Identical config but in public subnet 2 (AZ-2).
# Together, both instances form a multi-AZ pair behind the ALB.
resource "aws_instance" "web_2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name

  user_data = <<-EOF
   #!/bin/bash
   #Update package index
    apt-get update -y
    apt-get install -y apache2
   #Start and enable apache2 on boot#
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Hello from Instance 2 - AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.project_name}-web-instance-2"
    AZ   = var.az_2
  }
}
