# Personal Steam Infrastructure (AWS Academy Edition)

This project provides the Terraform configuration to deploy a "Personal Steam" infrastructure on AWS Academy using the restricted `LabRole`.

## 📦 What's included:
- **Networking**: Route 53 Public Zone + ACM SSL Certificate.
- **Compute**:
    - **ECS (Fargate)**: For backend APIs with S3 integration.
    - **Elastic Beanstalk**: Docker environment for background workers.
- **Database**: RDS PostgreSQL with encryption (KMS).
- **Storage**: S3 Bucket for game/file storage.
- **Frontend**: 2 AWS Amplify applications.

## 🚀 Deployment Instructions

### 1. Prerequisites
- [Terraform](https://www.terraform.io/downloads) installed.
- AWS CLI configured with your **Academy Session Token**.
- A domain name (to be managed via Cloudflare/Route 53).

### 2. Configuration
Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your details:
- `account_id`: Your 12-digit AWS Account ID.
- `domain_name`: The domain you own.
- `lab_role_name`: Usually `LabRole`.
- `lab_instance_profile_name`: Usually `LabInstanceProfile`.
- `cloudflare_api_token`: Your Cloudflare API Token (with DNS edit permissions).
- `cloudflare_zone_id`: The Zone ID for your domain in Cloudflare.

### 3. Apply
```bash
terraform init
terraform apply
```

### 4. Integration with Cloudflare
The infrastructure is now automated! 
1.  Terraform will automatically create the Route 53 zone.
2.  It will automatically update your **Cloudflare NS records** to point to AWS.
3.  Set Cloudflare SSL mode to **"Full (strict)"** in the dashboard.

## ⚠️ Academy Known Issues
- **Amplify**: Often fails during deployment due to IAM limitations. If it fails, consider deploying the frontends as Docker containers in the ECS cluster or Beanstalk.
- **ACM Validation**: DNS validation via Route 53 can take up to 30 minutes. If it hangs, verify that your Cloudflare NS records are correctly updated.
- **KMS**: We use the default `aws/rds` key to avoid permission errors when creating custom keys.
