# Terraform AWS Demo

Project Terraform để deploy hạ tầng web trên AWS môi trường Development.

## AWS Services đang sử dụng

| # | AWS Service | Mô tả |
|---|-------------|-------|
| 1 | **VPC (Virtual Private Cloud)** | Mạng riêng trên AWS, bao gồm public/private subnets, route tables, NAT Gateway, DNS support |
| 2 | **EC2 (Elastic Compute Cloud)** | 2 instances chạy Nginx web server, mỗi instance ở một Availability Zone khác nhau (us-east-1a, us-east-1b) |
| 3 | **S3 (Simple Storage Service)** | Bucket lưu trữ web assets, có versioning, encryption (AES256), lifecycle rules (chuyển sang Glacier sau 90 ngày) |
| 4 | **IAM (Identity and Access Management)** | 2 IAM Roles: Role 1 (SSM + S3 access) cho EC2-1, Role 2 (SSM only) cho EC2-2 |
| 5 | **Security Groups** | Firewalls cho EC2 instances (HTTP, HTTPS, SSH) và ELB (HTTP, HTTPS ingress; HTTP egress đến backends) |
| 6 | **ELB (Elastic Load Balancer)** | Classic Load Balancer phân phối traffic đến 2 Nginx servers, có health check HTTP:80/ |
| 7 | **VPC Endpoint** | Gateway Endpoint cho S3, cho phép truy cập S3 từ VPC mà không cần ra Internet |
| 8 | **NAT Gateway** | Cho phép EC2 ở private subnet kết nối ra Internet một cách bảo mật |

## Kiến trúc

```
                    Internet
                        │
                        ▼
              ┌───────────────┐
              │    ELB        │  (Classic Load Balancer)
              │  Port 80/443  │
              └───────┬───────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌──────────────────┐      ┌──────────────────┐
│   EC2 Instance 1 │      │   EC2 Instance 2 │
│  Nginx Server    │      │  Nginx Server    │
│  AZ us-east-1a   │      │  AZ us-east-1b   │
│  IAM Role 1      │      │  IAM Role 2      │
│  S3 Access: YES  │      │  S3 Access: NO   │
└──────────────────┘      └──────────────────┘
        │                           │
        └─────────┬─────────────────┘
                  ▼
          ┌──────────────┐
          │   AWS S3     │
          │  Web Assets  │
          └──────────────┘
```

## Cấu trúc module

```
modules/
├── terraform-aws-vpc/          # VPC, subnets, route tables, NAT Gateway
├── terraform-aws-ec2-instance/ # EC2 instances với user data, security group, IAM role
├── terraform-aws-elb/          # Classic Load Balancer
├── terraform-aws-iam/          # IAM Roles, instance profiles, inline policies
├── terraform-aws-s3-bucket/    # S3 bucket với versioning, encryption, lifecycle
└── terraform-aws-security-group/ # Security Groups (firewall rules)
```

## Cách deploy

```bash
# Khởi tạo Terraform
cd environments/dev
terraform init

# Xem plan
terraform plan

# Apply deploy
terraform apply