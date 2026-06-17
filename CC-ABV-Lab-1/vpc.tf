# ============================================================
#  vpc.tf
#  All networking primitives: VPC, subnets, internet gateway,
#  and the public route table with its subnet associations.
#
#  Other files reference outputs from this file, e.g.:
#    aws_vpc.main.id
#    aws_subnet.public_1.id
# ============================================================

# ── VPC ──────────────────────────────────────────────────────
# The top-level private network container. All resources live
# inside this VPC and are isolated from other AWS accounts.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # Required for Route53 and ELB DNS resolution
  enable_dns_hostnames = true # Assigns DNS names to EC2 instances

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ── Public Subnet 1 ──────────────────────────────────────────
# Lives in AZ-1. Hosts resources that need direct internet access.
# EC2 instances launched here receive a public IP automatically.
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
    Type = "public"
  }
}

# ── Public Subnet 2 ──────────────────────────────────────────
# Lives in AZ-2. The ALB requires subnets in at least two AZs.
# Spreading instances here ensures survival if AZ-1 goes down.
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
    Type = "public"
  }
}

# ── Internet Gateway ─────────────────────────────────────────
# The single entry/exit point between the VPC and the internet.
# One IGW per VPC — attaching it here makes the VPC internet-capable.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ── Public Route Table ───────────────────────────────────────
# Any subnet associated with this table can reach the internet
# via the IGW. The 0.0.0.0/0 route is what makes a subnet "public".
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# ── Route Table Associations ─────────────────────────────────
# Without these, subnets use the VPC's default route table which
# has no internet route. Associating here "activates" public access.
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
