# Terraform AWS Multi-Environment Infrastructure

Modular Terraform project that builds the same AWS infrastructure for **dev**, **staging** and **prod** from one codebase. The environment is selected with `var.env`, a Terraform **workspace** and a per-environment `.tfvars` file.

## What gets created

| Component | Details |
|---|---|
| **VPC** | Custom VPC, 2 public + 2 private subnets across 2 AZs, Internet Gateway, route tables (no NAT gateway) |
| **Security Group** | Ingress ports controlled per environment |
| **EC2** | Ubuntu 22.04 instances spread across public subnets, with an auto-generated SSH key |
| **S3** | Versioned bucket with all public access blocked |
| **DynamoDB** | Table with `id` hash key (PAY_PER_REQUEST) |
| **Remote backend** | State in S3 with DynamoDB locking |

## Environments

| Setting | dev | staging | prod |
|---|---|---|---|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Public subnets | 10.0.1.0/24, 10.0.2.0/24 | 10.1.1.0/24, 10.1.2.0/24 | 10.2.1.0/24, 10.2.2.0/24 |
| Private subnets | 10.0.3.0/24, 10.0.4.0/24 | 10.1.3.0/24, 10.1.4.0/24 | 10.2.3.0/24, 10.2.4.0/24 |
| Instance type | t2.micro | t3.small | t3.medium |
| Instance count | 2 | 3 | 3 |
| Open ports | 22, 80, 443 | 22, 80, 443 | 80, 443 |
| SSH key | `dev-terra-key` | `staging-terra-key` | `prod-terra-key` |
| S3 bucket | `<bucket_name>-dev` | `<bucket_name>-staging` | `<bucket_name>-prod` |

Instances are named `<env>-server-1`, `<env>-server-2`, and so on.

## Project structure

```
terraform-project/
├── providers.tf          # Terraform + provider versions, S3 backend
├── main.tf               # Calls all modules
├── variables.tf          # Root input variables
├── outputs.tf            # Root outputs
├── .gitignore
├── envs/
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── keys/                 # Auto-generated SSH keys (git-ignored)
└── modules/
    ├── vpc/
    ├── security_group/
    ├── ec2/
    ├── dynamodb/
    └── s3/
```

Each module has its own `main.tf`, `variables.tf` and `outputs.tf`.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`aws configure`)
- An AWS account with permissions for VPC, EC2, S3 and DynamoDB

## Setup

### 1. Create the remote backend (one time only)

The state bucket and lock table must exist before `terraform init`. Replace the bucket name with a globally unique one.

```bash
aws s3api create-bucket \
  --bucket onkar-terra-state-1817 \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

aws s3api put-bucket-versioning \
  --bucket onkar-terra-state-1817 \
  --versioning-configuration Status=Enabled

aws dynamodb create-table \
  --table-name terra-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-west-2
```

Then make sure the `backend "s3"` block in `providers.tf` uses the same bucket and table names.

### 2. Set your bucket name

In each `envs/*.tfvars` file, set a base name for the app bucket (must be globally unique, lowercase):

```hcl
bucket_name = "onkar-terra-bucket"
```

The environment is appended automatically, for example `onkar-terra-bucket-dev`.

### 3. Initialize

```bash
terraform init
```

## Deploy an environment

Always use the workspace and the tfvars file of the **same** environment.

```bash
# dev
terraform workspace new dev          # first time only
terraform workspace select dev
terraform plan  -var-file=envs/dev.tfvars
terraform apply -var-file=envs/dev.tfvars
```

Repeat for staging and prod:

```bash
terraform workspace new staging
terraform apply -var-file=envs/staging.tfvars

terraform workspace new prod
terraform apply -var-file=envs/prod.tfvars
```

Useful commands:

```bash
terraform workspace list             # shows all workspaces (* = current)
terraform workspace show             # current workspace
terraform output                     # show outputs of current env
```

## SSH key (generated automatically)

No manual `ssh-keygen` is needed. The EC2 module generates a key pair during `terraform apply`, registers the public key in AWS as `<env>-terra-key`, and saves the private key to `keys/<env>-terra-key.pem` with permission `0400`.

How it works (`modules/ec2/main.tf`):

```hcl
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh
  tags       = var.tags
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.root}/keys/${var.key_name}.pem"
  file_permission = "0400"
}
```

This requires the `tls` and `local` providers in `providers.tf`.

Connect to an instance:

```bash
terraform output ssh_commands
ssh -i keys/dev-terra-key.pem ubuntu@<public_ip>
```

> Prod has port 22 closed. To SSH into prod, temporarily add `22` to `allowed_ports` in `envs/prod.tfvars` and apply.

## Outputs

| Output | Description |
|---|---|
| `environment` | Current environment |
| `vpc_id` | VPC ID |
| `public_subnet_ids` / `private_subnet_ids` | Subnet IDs |
| `ssh_key_name` | Name of the generated key pair |
| `ec2_instances` | Map of instance name to id, public IP and private IP |
| `ssh_commands` | Ready-to-use SSH commands |
| `dynamodb_table` | DynamoDB table name |
| `s3_bucket` | S3 bucket name |

## Destroy

```bash
terraform workspace select dev
terraform destroy -var-file=envs/dev.tfvars
```

Do not destroy the remote state bucket or lock table while any environment still exists.

## Notes

- **AWS main route table:** AWS creates one default route table for every VPC. The VPC module uses it as the private route table, so there are two named route tables: `<name>-public-rt` and `<name>-private-rt`.
- **No NAT gateway:** private subnets have no internet access. NAT can be added later by adding a route in the private route table.
- **Cost:** EC2 instances (especially 3 x t3.medium in prod) cost money while running. Destroy environments you are not using.
- **Security:** open SSH (`0.0.0.0/0` on port 22) is acceptable for learning only. Restrict it to your own IP for real use.
- **Key in state:** auto-generated private keys are stored in the Terraform state. Keep the state bucket private and encrypted.

## Troubleshooting

| Problem | Fix |
|---|---|
| `Reference to undeclared input variable` | The variable is missing in the root `variables.tf` |
| `BucketAlreadyExists` | Change `bucket_name` to something unique |
| `UNPROTECTED PRIVATE KEY FILE` | Run `chmod 400 keys/<env>-terra-key.pem` |
| `Permission denied (publickey)` | Use the `ubuntu` user for Ubuntu AMIs |
| SSH timeout | Port 22 is not open for that environment |
| Wrong environment applied | Check `terraform workspace show` matches the `-var-file` |

## Author

Onkar Ghugare, [GitHub](https://github.com/onkar-1817)
