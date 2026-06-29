# ============================================================
#  main.tf  — ROOT
#  This is the only file you ever run terraform plan/apply on.
#  It calls each module like a function, passing in the right
#  values for whichever workspace is currently selected.
#
#  Flow:
#    terraform workspace select dev
#    terraform apply -var-file="envs/dev.tfvars"
#    → all modules deploy with dev-sized resources
#
#    terraform workspace select prod
#    terraform apply -var-file="envs/prod.tfvars"
#    → same modules, prod-sized resources, separate state file
# ============================================================

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = terraform.workspace   # always reflects active workspace
      ManagedBy   = "Terraform"
    }
  }
}

# ── Workspace-aware locals ────────────────────────────────────
# terraform.workspace returns the active workspace name as a string.
# Each map key corresponds to one workspace.
# Adding a new environment = add a new key to each map.
locals {
  env = terraform.workspace

  # Instance sizing per environment
  instance_type = {
    dev     = "t2.nano"
    staging = "t2.micro"
    prod    = "t3.large"
  }

  # Number of EC2 instances per environment
  instance_count = {
    dev     = 1
    staging = 2
    prod    = 4
  }

  # VPC CIDR per environment — each env gets its own IP space
  # so they never overlap if you ever need to peer them
  vpc_cidr = {
    dev     = "10.1.0.0/16"
    staging = "10.2.0.0/16"
    prod    = "10.3.0.0/16"
  }

  subnet_1_cidr = {
    dev     = "10.1.0.0/24"
    staging = "10.2.0.0/24"
    prod    = "10.3.0.0/24"
  }

  subnet_2_cidr = {
    dev     = "10.1.1.0/24"
    staging = "10.2.1.0/24"
    prod    = "10.3.1.0/24"
  }
}

# ── MODULE: VPC ───────────────────────────────────────────────
# Creates VPC, 2 public subnets, IGW, route table.
# Outputs vpc_id and subnet IDs used by all other modules.
module "vpc" {
  source = "./modules/vpc"

  project_name  = var.project_name
  environment   = local.env
  vpc_cidr      = local.vpc_cidr[local.env]
  subnet_1_cidr = local.subnet_1_cidr[local.env]
  subnet_2_cidr = local.subnet_2_cidr[local.env]
  az_1          = var.az_1
  az_2          = var.az_2
}

# ── MODULE: Security Group ────────────────────────────────────
# Creates the web security group inside the VPC created above.
# Needs vpc_id from the vpc module output.
module "sg" {
  source = "./modules/sg"

  project_name = var.project_name
  environment  = local.env
  vpc_id       = module.vpc.vpc_id   # reading vpc module output
}

# ── MODULE: EC2 ───────────────────────────────────────────────
# Deploys instances into the subnets created by the vpc module.
# Count and type come from the workspace-aware locals above.
module "ec2" {
  source = "./modules/ec2"

  project_name      = var.project_name
  environment       = local.env
  ami_id            = var.ami_id
  instance_type     = local.instance_type[local.env]
  instance_count    = local.instance_count[local.env]
  subnet_ids        = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  security_group_id = module.sg.web_sg_id
  public_key_path   = var.public_key_path
}

# ── MODULE: ALB ───────────────────────────────────────────────
# Creates ALB, target group, listener, and attaches EC2 instances.
# Needs subnet IDs and SG from earlier modules.
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = local.env
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = [module.vpc.public_subnet_1_id, module.vpc.public_subnet_2_id]
  security_group_id = module.sg.web_sg_id
  instance_ids      = module.ec2.instance_ids   # list of all EC2 IDs
}

# ── MODULE: S3 ────────────────────────────────────────────────
# Creates an S3 bucket with versioning, encryption, and
# public access block. Bucket name is unique per environment.
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = local.env
  bucket_name  = "${var.project_name}-${local.env}-app-bucket"
}
