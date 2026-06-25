# =====================================================
# VPC Outputs
# =====================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

# =====================================================
# S3 Bucket Outputs
# =====================================================

output "s3_bucket_id" {
  description = "The S3 bucket name for web assets"
  value       = module.web_assets_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The S3 bucket ARN"
  value       = module.web_assets_bucket.s3_bucket_arn
}

# =====================================================
# IAM Role Outputs
# =====================================================

output "iam_role_1_name" {
  description = "IAM Role 1 name (has S3 access)"
  value       = module.nginx_web_role_1.name
}

output "iam_role_1_arn" {
  description = "IAM Role 1 ARN (has S3 access)"
  value       = module.nginx_web_role_1.arn
}

output "iam_role_2_name" {
  description = "IAM Role 2 name (NO S3 access)"
  value       = module.nginx_web_role_2.name
}

output "iam_role_2_arn" {
  description = "IAM Role 2 ARN (NO S3 access)"
  value       = module.nginx_web_role_2.arn
}

# =====================================================
# EC2 Instance Outputs
# =====================================================

output "instance_ids" {
  description = "Map of EC2 instance IDs"
  value       = { for k, inst in module.nginx_ec2_instances : k => inst.id }
}

output "instance_public_ips" {
  description = "Map of EC2 instance public IPs"
  value       = { for k, inst in module.nginx_ec2_instances : k => inst.public_ip }
}

output "instance_private_ips" {
  description = "Map of EC2 instance private IPs"
  value       = { for k, inst in module.nginx_ec2_instances : k => inst.private_ip }
}

output "instance_urls" {
  description = "Direct URLs to each Nginx server"
  value       = { for k, inst in module.nginx_ec2_instances : k => "http://${inst.public_ip}" }
}

# =====================================================
# ELB Outputs
# =====================================================

output "elb_dns_name" {
  description = "The DNS name of the ELB"
  value       = module.elb.elb_dns_name
}

output "elb_url" {
  description = "URL to access Nginx via ELB (Load Balanced)"
  value       = "http://${module.elb.elb_dns_name}"
}

output "elb_id" {
  description = "The ID of the ELB"
  value       = module.elb.elb_id
}