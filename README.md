# Terraform AWS Demo

Project Terraform triển khai hạ tầng web trên AWS cho hai môi trường `dev` và `prod`. Source code được lưu trên GitHub; Terraform state được lưu trong S3 có mã hóa, versioning và state locking.

## AWS services

- VPC, public/private subnets, route tables và NAT Gateway.
- EC2 chạy Nginx; môi trường dev có hai instance ở hai Availability Zone.
- IAM roles và instance profiles cho EC2.
- S3 bucket cho web assets và một S3 bucket riêng cho Terraform state.
- Security Groups và VPC Endpoint cho S3.

ELB đã được loại bỏ. Nginx hiện được truy cập trực tiếp qua public IP của EC2.

## Cấu trúc chính

```text
bootstrap/          # Tạo S3 bucket lưu Terraform state
environments/dev/   # Hạ tầng môi trường development
environments/prod/  # Hạ tầng môi trường production
modules/            # Các Terraform module dùng chung
```

## 1. Tạo state bucket một lần

Chọn một bucket name duy nhất trên toàn AWS, copy `bootstrap/terraform.tfvars.example` thành `bootstrap/terraform.tfvars`, cập nhật giá trị rồi chạy:

```powershell
terraform -chdir=bootstrap init
terraform -chdir=bootstrap apply
```

Sau lần apply đầu tiên, copy `bootstrap/backend.hcl.example` thành `bootstrap/backend.hcl`, rồi migrate bootstrap state lên S3:

```powershell
terraform -chdir=bootstrap init -migrate-state -force-copy -backend-config backend.hcl
```

## 2. Cấu hình và migrate state

Trong từng environment, copy `backend.hcl.example` thành `backend.hcl`, thay bucket placeholder bằng bucket vừa tạo, rồi chạy:

```powershell
terraform -chdir=environments/dev init -migrate-state -backend-config backend.hcl
terraform -chdir=environments/prod init -migrate-state -backend-config backend.hcl
```

Hai môi trường sử dụng hai S3 object key riêng và S3-native state locking.

## 3. Deploy

Ví dụ với môi trường dev:

```powershell
terraform -chdir=environments/dev plan
terraform -chdir=environments/dev apply
```

Không commit `.tfstate`, `.terraform/`, `.env`, credentials, `backend.hcl` hoặc file `*.tfvars` thực tế lên GitHub. Các file `.terraform.lock.hcl` nên được commit để cố định dependency versions.
