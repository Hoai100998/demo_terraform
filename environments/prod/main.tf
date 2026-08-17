# =====================================================
# VPC Module
# =====================================================

module "vpc" {
  source = "../../modules/terraform-aws-vpc"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT Gateway settings - enabled for production
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = var.common_tags
}
# =====================================================
# EC2 Instance Module - Nginx Web Server
# =====================================================

module "nginx_ec2_instance" {
  source = "../../modules/terraform-aws-ec2-instance"

  name = var.instance_name

  # AMI
  ami = var.ami

  # Instance configuration
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnets[0]

  # User data to install and start Nginx
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              # Create a welcome page
              cat > /usr/share/nginx/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                <title>Welcome to Nginx on AWS</title>
                <style>
                  body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: #f5f5f5; }
                  .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); display: inline-block; }
                  h1 { color: #007cff; }
                  p { color: #555; }
                </style>
              </head>
              <body>
                <div class="container">
                  <h1>Nginx is running!</h1>
                  <p>This server was deployed using Terraform.</p>
                  <p>Environment: PROD</p>
                  <p>Instance: ${var.instance_name}</p>
                </div>
              </body>
              </html>
              HTML
              EOF

  # Associate public IP
  associate_public_ip_address = true

  # Security Group
  create_security_group = true
  security_group_name   = "${var.instance_name}-sg"
  security_group_vpc_id = module.vpc.vpc_id

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP traffic"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS traffic"
    }
    ssh = {
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow SSH traffic"
    }
  }

  # Root block device
  root_block_device = {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  # Metadata options
  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  # Tags
  tags = var.common_tags
}

