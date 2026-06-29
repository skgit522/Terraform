# modules/vpc/variables.tf
variable "project_name"  { type = string }
variable "environment"   { type = string }
variable "vpc_cidr"      { type = string }
variable "subnet_1_cidr" { type = string }
variable "subnet_2_cidr" { type = string }
variable "az_1"          { type = string }
variable "az_2"          { type = string }
