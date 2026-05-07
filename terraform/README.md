# Terraform — StatusPulse Infrastructure

This Terraform configuration provisions a hardened Ubuntu server on AWS for running StatusPulse.

## What It Provisions

- **EC2 Instance** (t2.micro — free tier eligible)
- **Security Group** with only ports 2222 (SSH), 80 (HTTP), 443 (HTTPS)
- **Cloud-Init** that automatically:
  - Installs Docker & Docker Compose
  - Configures UFW firewall
  - Hardens SSH (disable root login, password auth, custom port 2222)
  - Creates 1GB swap space
  - Creates a `deploy` user with Docker access
  - Sets up cron jobs for monitoring and backups

## Prerequisites

1. [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
2. AWS CLI configured with credentials (`aws configure`)
3. An existing SSH key pair in AWS

## Usage

```bash
# Initialize Terraform
cd terraform/
terraform init

# Preview changes
terraform plan -var="key_name=my-key" -var="domain_name=status.example.com" -var="admin_email=admin@example.com"

# Apply
terraform apply -var="key_name=my-key" -var="domain_name=status.example.com" -var="admin_email=admin@example.com"
```

## After Provisioning

1. Point your domain's DNS A record to the output `public_ip`.
2. SSH into the server:
   ```bash
   ssh -p 2222 deploy@<public_ip>
   ```
3. Clone the repo and start the stack:
   ```bash
   cd ~/statuspulse
   git clone <your-repo> .
   cp .env.example .env
   # Edit .env with real values
   docker compose up -d
   ```

## Tear Down

```bash
terraform destroy -var="key_name=my-key" -var="domain_name=status.example.com" -var="admin_email=admin@example.com"
```
