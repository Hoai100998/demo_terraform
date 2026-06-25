# =====================================================
# VPC Module
# =====================================================

module "vpc" {
  source = "../../modules/terraform-aws-vpc"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = var.availability_zones
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true

  # NAT Gateway settings
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = var.common_tags
}

# =====================================================
# IAM Role 1 - EC2 Instance 1 (SSM + S3 Full Access via Inline Policy)
# =====================================================

module "nginx_web_role_1" {
  source = "../../modules/terraform-aws-iam/modules/iam-role"

  name        = "dev-nginx-web-role-1"
  description = "IAM role for Nginx Server 1 - S3 access via inline policy"

  create_instance_profile = true

  # Managed policy: SSM Session Manager
  policies = {
    SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Inline policy: FULL S3 access to specific bucket
  create_inline_policy = true
  inline_policy_permissions = {
    # SID must be alphanumeric only [0-9A-Za-z]* — no underscores!
    s3full = {
      effect  = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload"
      ]
      resources = [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    }
  }

  # Trust policy: allow EC2 to assume this role
  trust_policy_permissions = {
    ec2 = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "Service"
          identifiers = ["ec2.amazonaws.com"]
        }
      ]
    }
  }

  tags = var.common_tags
}

# =====================================================
# IAM Role 2 - EC2 Instance 2 (SSM Only, NO S3 Access)
# =====================================================

module "nginx_web_role_2" {
  source = "../../modules/terraform-aws-iam/modules/iam-role"

  name        = "dev-nginx-web-role-2"
  description = "IAM role for Nginx Server 2 - NO S3 access"

  create_instance_profile = true

  # Managed policy: SSM Session Manager only
  policies = {
    SSM = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # NO S3 policy = NO S3 access (implicit deny)

  # Trust policy: allow EC2 to assume this role
  trust_policy_permissions = {
    ec2 = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [
        {
          type        = "Service"
          identifiers = ["ec2.amazonaws.com"]
        }
      ]
    }
  }

  tags = var.common_tags
}

# =====================================================
# S3 Bucket Module - Web Assets Storage
# No bucket policy — AWS Console/root can access normally.
# EC2-1 (Role 1) gets S3 access via IAM inline policy.
# EC2-2 (Role 2) has NO S3 access (no IAM policy).
# =====================================================

module "web_assets_bucket" {
  source = "../../modules/terraform-aws-s3-bucket"

  bucket = var.s3_bucket_name

  # Versioning
  versioning = { enabled = var.s3_bucket_versioning }

  # Encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = var.s3_bucket_encryption
      }
    }
  }

  # Security: deny unencrypted uploads
  attach_deny_unencrypted_object_uploads = var.s3_bucket_deny_unencrypted_uploads

  # Lifecycle: expire old objects after N days
  lifecycle_rule = [
    {
      id     = "expire-old-objects"
      status = "Enabled"
      expiration = {
        days = var.s3_lifecycle_expiration_days
      }
    }
  ]

  tags = var.common_tags
}

# =====================================================
# EC2 Instances - Using for_each to avoid code duplication
# 2 instances in 2 different AZs
# =====================================================

locals {
  instances = {
    "1" = {
      name            = "${var.instance_name}-1"
      subnet_index    = 0
      az              = "us-east-1a"
      color_bg        = "#e3f2fd"
      color_fg        = "#2196F3"
      s3_access_label = "YES"
      iam_role        = module.nginx_web_role_1.instance_profile_name
    }
    "2" = {
      name            = "${var.instance_name}-2"
      subnet_index    = 1
      az              = "us-east-1b"
      color_bg        = "#fce4ec"
      color_fg        = "#E91E63"
      s3_access_label = "NO"
      iam_role        = module.nginx_web_role_2.instance_profile_name
    }
  }

  # SSH rules: create dynamic rules from var.ssh_allowed_ips
  ssh_rules = { for idx, ip in var.ssh_allowed_ips : "ssh_${idx}" => {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr_ipv4   = ip
    description = "Allow SSH from ${ip}"
  }}
}

module "nginx_ec2_instances" {
  source = "../../modules/terraform-aws-ec2-instance"

  for_each = local.instances

  name = each.value.name

  # AMI: use variable if set, otherwise module default (SSM parameter for latest AL2023)
  ami = var.ami

  # Instance configuration
  instance_type = var.instance_type
  subnet_id     = module.vpc.public_subnets[each.value.subnet_index]

  # user_data: install Nginx with custom page per instance
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              systemctl start nginx
              systemctl enable nginx
              mkdir -p /usr/share/nginx/html
              cat > /usr/share/nginx/html/index.html << 'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                <title>Nginx Server ${each.key}</title>
                <style>
                  body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: ${each.value.color_bg}; }
                  .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); display: inline-block; }
                  h1 { color: ${each.value.color_fg}; }
                  p { color: #555; }
                </style>
              </head>
              <body>
                <div class="container">
                  <h1>Nginx Server ${each.key} is running!</h1>
                  <p>This server was deployed using Terraform.</p>
                  <p>Environment: DEV</p>
                  <p>AZ: ${each.value.az}</p>
                  <p>S3 Access: ${each.value.s3_access_label}</p>
                </div>
              </body>
              </html>
              HTML
              systemctl restart nginx
              EOF

  # Public IP (only for dev; Production: use private subnet + NLB)
  associate_public_ip_address = true

  # Security Group
  create_security_group = true
  security_group_name   = "${var.instance_name}-${each.key}-sg"
  security_group_vpc_id = module.vpc.vpc_id

  security_group_ingress_rules = merge(
    {
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
    },
    local.ssh_rules
  )

  # Root disk
  root_block_device = {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  # Metadata: IMDSv2 enforced (security best practice)
  metadata_options = {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "required"
  }

  # IAM: attach instance profile from IAM Role modules
  create_iam_instance_profile = false
  iam_instance_profile        = each.value.iam_role

  tags = merge(var.common_tags, {
    Server   = each.key
    AZ       = each.value.az
    S3Access = each.value.s3_access_label
  })
}

# =====================================================
# Security Group for Public ELB
# =====================================================

module "elb_security_group" {
  source = "../../modules/terraform-aws-security-group"

  name        = "${var.vpc_name}-elb-sg"
  description = "Security group for public ELB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTP traffic from anywhere"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "Allow HTTPS traffic from anywhere"
    }
  }

  # Egress: restrict to only port 80 within VPC
  egress_rules = {
    http_to_backends = {
      ip_protocol = "tcp"
      to_port     = 80
      cidr_ipv4   = var.vpc_cidr
      description = "Allow HTTP to backend EC2 instances in VPC"
    }
  }

  tags = var.common_tags
}

# =====================================================
# ELB Module - Classic Load Balancer for 2 Nginx Servers
# NOTE: Classic ELB is deprecated. Consider migrating to ALB.
# =====================================================

module "elb" {
  source = "../../modules/terraform-aws-elb"

  name = "${var.vpc_name}-elb"

  # Subnets: place ELB in public subnets (both AZs for HA)
  subnets = module.vpc.public_subnets

  # Security Group for ELB
  security_groups = [module.elb_security_group.id]

  # Listener: forward HTTP on port 80 to Nginx on port 80
  listener = [
    {
      instance_port     = 80
      instance_protocol = "http"
      lb_port           = 80
      lb_protocol       = "http"
    }
  ]

  # Health Check: check Nginx on port 80
  health_check = {
    target              = "HTTP:80/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  # Attach 2 EC2 instances to ELB
  number_of_instances = length(local.instances)
  instances           = [for inst in module.nginx_ec2_instances : inst.id]

  # ELB settings
  internal                 = false
  cross_zone_load_balancing = true
  idle_timeout             = 60
  connection_draining      = true
  connection_draining_timeout = 300

  tags = var.common_tags
}