# =====================================================
# Provider Variables
# =====================================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
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
}

variable "availability_zones" {
  description = "Availability zones to deploy resources"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # Cập nhật các Availability Zones theo khu vực của bạn
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Cập nhật các CIDR block cho public subnets theo nhu cầu của bạn
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"] # Cập nhật các CIDR block cho private subnets theo nhu cầu của bạn
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false # Cập nhật giá trị này thành true nếu bạn muốn bật NAT Gateway trong môi trường dev
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true # Cập nhật giá trị này thành true nếu bạn muốn sử dụng một NAT Gateway duy nhất cho tất cả các private subnets
}

# =====================================================
# EC2 Instance Variables
# =====================================================

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "dev-nginx-server"
}

variable "ami" {
  description = "ID of AMI to use for the instance"
  type        = string
  default     = "ami-08f44e8eca9095668"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {  # Cập nhật biến root_volume_size để xác định kích thước ổ đĩa gốc của EC2 instance
  description = "Root volume size in GB"
  type        = number  
  default     = 8 # Cập nhật giá trị mặc định của root_volume_size theo nhu cầu của bạn
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