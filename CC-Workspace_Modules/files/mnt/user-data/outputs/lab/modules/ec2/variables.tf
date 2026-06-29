# modules/ec2/variables.tf
variable "project_name"      { type = string }
variable "environment"       { type = string }
variable "ami_id"            { type = string }
variable "instance_type"     { type = string }
variable "instance_count"    { type = number }
variable "subnet_ids"        { type = list(string) }
variable "security_group_id" { type = string }
variable "public_key_path"   { type = string }
