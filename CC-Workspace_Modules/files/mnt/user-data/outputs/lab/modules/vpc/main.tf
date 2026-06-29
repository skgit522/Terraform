# ============================================================
#  modules/vpc/main.tf
#  Reusable networking module.
#  Called by root main.tf for every environment.
#  The environment name is embedded in every resource Name tag
#  so dev-vpc and prod-vpc are clearly separate in the console.
# ============================================================

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-${var.environment}-vpc" }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_1_cidr
  availability_zone       = var.az_1
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-${var.environment}-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.subnet_2_cidr
  availability_zone       = var.az_2
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-${var.environment}-public-subnet-2" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project_name}-${var.environment}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.project_name}-${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
