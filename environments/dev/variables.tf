# =====================================================
# Provider Variables
# =====================================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)."
  }
}

# =====================================================
# VPC Variables
# =====================================================

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "dev-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones to deploy resources"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

# =====================================================
# EC2 Instance Variables
# =====================================================

variable "instance_name" {
  description = "Name prefix of the EC2 instances"
  type        = string
  default     = "dev-nginx-server"
}

variable "ami" {
  description = "ID of AMI to use for the instance. If null, uses latest Amazon Linux 2023 from SSM"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[23]", var.instance_type))
    error_message = "Instance type should be a t2 or t3 instance for this configuration."
  }
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 8GB and 1000GB."
  }
}

variable "ssh_allowed_ips" {
  description = "List of CIDR blocks allowed to SSH into EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for ip in var.ssh_allowed_ips : can(cidrhost(ip, 0))])
    error_message = "All SSH allowed IPs must be valid CIDR blocks."
  }
}

# =====================================================
# S3 Bucket Variables
# =====================================================

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for web assets (must be globally unique)"
  type        = string
  default     = "dev-nginx-assets-992382472914"

  validation {
    condition     = length(var.s3_bucket_name) >= 3 && length(var.s3_bucket_name) <= 63
    error_message = "S3 bucket name must be between 3 and 63 characters."
  }
}

variable "s3_bucket_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "s3_bucket_encryption" {
  description = "Encryption algorithm for the S3 bucket"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.s3_bucket_encryption)
    error_message = "S3 bucket encryption must be AES256 or aws:kms."
  }
}

variable "s3_bucket_deny_unencrypted_uploads" {
  description = "Deny uploads of unencrypted objects to the S3 bucket. Set to false for dev (aws s3 cp default is unencrypted)"
  type        = bool
  default     = false
}

variable "s3_lifecycle_expiration_days" {
  description = "Number of days before noncurrent objects expire"
  type        = number
  default     = 90

  validation {
    condition     = var.s3_lifecycle_expiration_days > 0
    error_message = "S3 lifecycle expiration days must be greater than 0."
  }
}

# =====================================================
# Common Tags
# =====================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "nginx-webserver"
  }
}