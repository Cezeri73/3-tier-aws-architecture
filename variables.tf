variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS Region for the infrastructure"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.20.0.0/16"
  description = "CIDR block for the main VPC"
}

variable "project_name" {
  type        = string
  default     = "treetiercloudproject"
  description = "Base name for naming resources" # 
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance size for the Compute tier"
}

variable "db_username" {
  description = "Database administrator username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database administrator password"
  type        = string
  sensitive   = true
}