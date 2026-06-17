# ============================================================
#  AWS Infrastructure - Terraform Configuration
#  Provisions: VPC, Subnets, IGW, Route Table, Security Group,
#              EC2 Instances, ALB, Target Group, S3, Key Pair
# ============================================================


# ── VPC ──────────────────────────────────────────────────────
# Creates an isolated virtual network in AWS with a /16 CIDR block,
# giving us 65,536 private IP addresses to distribute across subnets.
resource "aws_vpc" "sk-tf-vpc" {
  cidr_block = "10.1.0.0/16"
}


# ── Public Subnet 1 ──────────────────────────────────────────
# Carved out of the VPC's address space. Placed in AZ ap-south-1a
# for high availability. map_public_ip_on_launch = true means any
# EC2 launched here automatically gets a public IPv4 address.
# NOTE: CIDR must be within the VPC range (10.1.0.0/16).
#       10.0.0.0/24 is OUTSIDE that range — fix this in production.
resource "aws_subnet" "tf-subnet_1" {
  vpc_id                  = aws_vpc.sk-tf-vpc.id
  cidr_block              = "10.1.0.0/24" # BUG FIX: was 10.0.0.0/24 (outside VPC CIDR)
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}


# ── Public Subnet 2 ──────────────────────────────────────────
# Second subnet in a different AZ (ap-south-1b) for multi-AZ
# redundancy. The ALB requires subnets in at least two AZs.
resource "aws_subnet" "tf-subnet_2" {
  vpc_id                  = aws_vpc.sk-tf-vpc.id
  cidr_block              = "10.1.1.0/24" # BUG FIX: was 10.0.1.0/24 (outside VPC CIDR)
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
}


# ── Internet Gateway ─────────────────────────────────────────
# Attaches to the VPC and acts as the bridge between our private
# network and the public internet. Without this, no traffic can
# flow in or out of the VPC.
resource "aws_internet_gateway" "tf-igw" {
  vpc_id = aws_vpc.sk-tf-vpc.id
}


# ── Public Route Table ───────────────────────────────────────
# Defines routing rules for the VPC. The 0.0.0.0/0 route sends
# all non-local traffic out through the Internet Gateway, making
# associated subnets "public".
resource "aws_route_table" "tf-pub_route" {
  vpc_id = aws_vpc.sk-tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-igw.id # BUG FIX: was igw.id (wrong reference name)
  }
}


# ── Route Table Associations ─────────────────────────────────
# Links the public route table to each subnet. Without these,
# the subnets would use the default (local-only) VPC route table
# and have no internet access.
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.tf-subnet_1.id       # BUG FIX: missing .id attribute
  route_table_id = aws_route_table.tf-pub_route.id # BUG FIX: missing .id attribute
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.tf-subnet_2.id       # BUG FIX: missing .id attribute
  route_table_id = aws_route_table.tf-pub_route.id # BUG FIX: missing .id attribute
}


# ── Security Group ───────────────────────────────────────────
# Acts as a stateful virtual firewall at the instance level.
# Inbound: allows HTTP (80) from anywhere and SSH (22) from anywhere.
# Outbound: allows all traffic out (needed for package installs, etc.)
# WARNING: SSH open to 0.0.0.0/0 is fine for learning but should be
#          restricted to your IP in any real environment.
resource "aws_security_group" "websg" {
  name        = "web"
  description = "Allow HTTP inbound and all outbound traffic"
  vpc_id      = aws_vpc.sk-tf-vpc.id # BUG FIX: was sk-tf-vpc (missing .id attribute)

  tags = {
    Name = "Allow_WEB"
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ── S3 Bucket ────────────────────────────────────────────────
# General-purpose object storage bucket. Could be used to store
# application assets, logs, or Terraform state (with versioning).
# NOTE: S3 bucket names must be globally unique across all AWS accounts.
#       Using underscores in the name is not allowed; use hyphens instead.
resource "aws_s3_bucket" "tf_s3_bucket" {
  bucket = "tf-s3-bucket" # BUG FIX: underscores not allowed in S3 names
}


# ── SSH Key Pair ─────────────────────────────────────────────
# Registers your local public key with AWS so it can be injected
# into EC2 instances at launch. You use the corresponding private key
# (id_rsa) to SSH into the instances later.
resource "aws_key_pair" "tf-instance-key" {
  key_name   = "tf-instance-key"
  public_key = file("${path.module}/id_rsa.pub")
}


# ── EC2 Instance 1 ───────────────────────────────────────────
# A small virtual machine placed in Subnet 1 (ap-south-1a).
# The AMI is an Amazon Machine Image (OS template) for ap-south-1 region.
# t2.nano is the smallest instance type — good for low-traffic/demo workloads.
resource "aws_instance" "TF-instance_1" {
  ami                    = "ami-05d2d839d4f73aafb"
  instance_type          = "t2.nano"
  subnet_id              = aws_subnet.tf-subnet_1.id
  vpc_security_group_ids = [aws_security_group.websg.id]
  key_name               = aws_key_pair.tf-instance-key.key_name

  tags = {
    Name = "sk-tf-nano_1"
  }
}


# ── EC2 Instance 2 ───────────────────────────────────────────
# Identical to Instance 1 but placed in Subnet 2 (ap-south-1b).
# Running instances in two AZs ensures the app stays up if one
# availability zone has an outage.
resource "aws_instance" "TF-instance_2" {
  ami                    = "ami-05d2d839d4f73aafb"
  instance_type          = "t2.nano"
  subnet_id              = aws_subnet.tf-subnet_2.id
  vpc_security_group_ids = [aws_security_group.websg.id]
  key_name               = aws_key_pair.tf-instance-key.key_name

  tags = {
    Name = "sk-tf-nano_2" # BUG FIX: was "sk-tf-nano_1" (duplicate tag, confusing)
  }
}


# ── Application Load Balancer ────────────────────────────────
# Sits in front of the EC2 instances and distributes incoming HTTP
# requests across them. "internal = false" makes it internet-facing.
# Requires at least two subnets in different AZs for fault tolerance.
resource "aws_lb" "tf-lb" {
  name               = "tf-lb" # BUG FIX: underscores not allowed in ALB names
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]                          # BUG FIX: missing .id attribute
  subnets            = [aws_subnet.tf-subnet_1.id, aws_subnet.tf-subnet_2.id] # BUG FIX: missing .id

  tags = {
    Name = "web-tf-lb"
  }
}


# ── Target Group ─────────────────────────────────────────────
# Defines the pool of backend targets (EC2 instances) the ALB routes
# traffic to. The health check pings "/" on port 80 to confirm instances
# are healthy before sending them real traffic.
resource "aws_lb_target_group" "tf_tg" {
  name     = "tf-tg" # BUG FIX: underscores and uppercase not allowed in TG names
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sk-tf-vpc.id # BUG FIX: missing .id attribute

  health_check {
    path = "/"
    port = "traffic-port"
  }
}


# ── Target Group Attachment 1 ────────────────────────────────
# Registers EC2 Instance 1 as a target in the target group.
# The ALB will start sending traffic to this instance once it
# passes the health check defined above.
resource "aws_lb_target_group_attachment" "lb_tg_1" {
  target_group_arn = aws_lb_target_group.tf_tg.arn
  target_id        = aws_instance.TF-instance_1.id
  port             = 80
}


# ── Target Group Attachment 2 ────────────────────────────────
# Registers EC2 Instance 2 in the same target group so the ALB
# can load balance across both instances.
resource "aws_lb_target_group_attachment" "lb_tg_2" {
  target_group_arn = aws_lb_target_group.tf_tg.arn
  target_id        = aws_instance.TF-instance_2.id # BUG FIX: missing .id attribute
  port             = 80
}


# ── ALB Listener ─────────────────────────────────────────────
# Tells the ALB to listen on port 80 for HTTP traffic and forward
# all matching requests to the target group. This is the entry point
# that connects the internet → ALB → target group → EC2 instances.
resource "aws_lb_listener" "tf_lb_listener" { # BUG FIX: typo "litener" corrected
  load_balancer_arn = aws_lb.tf-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tf_tg.arn
    type             = "forward"
  }
}


# ── Output ───────────────────────────────────────────────────
# After terraform apply, this prints the ALB's public DNS name to
# the terminal. Paste it into your browser to reach your application.
output "loadbalancerdns" {
  value       = aws_lb.tf-lb.dns_name
  description = "Public DNS name of the Application Load Balancer"
}
