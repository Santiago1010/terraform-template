# terraform-template

Production-grade AWS infrastructure template using Terraform — modular, cost-conscious, and built for a hybrid self-hosted/managed services architecture. Designed to evolve from MVP to scale without rework.

---

## Table of Contents

- [Why This Repository Exists](#why-this-repository-exists)
- [Architecture Overview](#architecture-overview)
- [What Terraform Is — and Why It Matters](#what-terraform-is--and-why-it-matters)
- [How Terraform Works](#how-terraform-works)
- [Repository Structure](#repository-structure)
- [Module Design Philosophy](#module-design-philosophy)
- [Why Variables](#why-variables)
- [Why Outputs](#why-outputs)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Expected Behavior After Apply](#expected-behavior-after-apply)
- [Cost Estimates](#cost-estimates)
- [Managed AWS Services — Failover Layer](#managed-aws-services--failover-layer)
- [Glossary](#glossary)

---

## Why This Repository Exists

Most infrastructure templates are either too simple to be useful in production, or so complex they require a dedicated platform team to understand. This template sits in between: it is production-ready, but designed to be readable by engineers who are still learning infrastructure as code.

The architecture follows a deliberate set of priorities, applied in strict order:

1. **Efficiency** — reliable, fault-tolerant, minimal operational overhead
2. **Economy** — every resource justifies its cost
3. **Scalability** — modular enough to evolve without rework
4. **Readability** — anyone reading the code should understand what is being built and why

When these priorities conflict, the higher one always wins. Economy never justifies sacrificing reliability. Scalability never justifies sacrificing economy when the traffic does not warrant it.

---

## Architecture Overview

The infrastructure follows a **hybrid strategy**: self-hosted services running on dedicated EC2 instances, with AWS managed equivalents available as commented-out modules for when operational complexity outgrows the self-hosted approach.

### Self-Hosted Services (Active)

Each service runs on its own dedicated EC2 instance. This keeps costs low and isolation clean.

| Service            | Purpose                             | Instance Type |
| ------------------ | ----------------------------------- | ------------- |
| Kong               | API Gateway / Ingress               | t3.small      |
| PostgreSQL (infra) | Vault and internal tooling database | t3.small      |
| PostgreSQL (app)   | Application database                | t3.small      |
| Redis              | Cache layer                         | t3.small      |
| HashiCorp Vault    | Secrets management                  | t3.small      |
| RabbitMQ           | Message queue / worker jobs         | t3.small      |
| Kafka              | Event streaming                     | t3.medium     |
| MongoDB            | Document store                      | t3.small      |
| Consul             | Service discovery and health checks | t3.small      |
| Observability      | Prometheus + Grafana + Loki + Tempo | t3.small      |
| n8n (infra)        | Infrastructure automation workflows | t3.small      |
| n8n (app)          | Business logic automation workflows | t3.small      |

### AWS Managed Services (Active)

| Service             | Purpose                           | Replaces                     |
| ------------------- | --------------------------------- | ---------------------------- |
| SQS                 | Managed message queues with DLQs  | RabbitMQ (simple use cases)  |
| Kinesis             | Managed event streaming           | Kafka (low-volume use cases) |
| CloudWatch Alarms   | Infrastructure-level alerting     | Complement to Prometheus     |
| Secrets Manager     | Bootstrap secrets storage         | Vault (pre-initialization)   |
| SSM Parameter Store | Service discovery via private IPs | Consul (complement)          |

### AWS Managed Services (Ready, Commented Out)

These modules are fully built and ready to activate. They are commented out because the self-hosted equivalents are already running and the cost-benefit does not justify the switch at low traffic volumes.

| Module              | Replaces           | Activate When                             |
| ------------------- | ------------------ | ----------------------------------------- |
| RDS (PostgreSQL)    | PostgreSQL EC2 × 2 | Multi-AZ or read replicas are needed      |
| ElastiCache (Redis) | Redis EC2          | Redis becomes a critical failure point    |
| DocumentDB          | MongoDB EC2        | Managed MongoDB compatibility is required |

---

## What Terraform Is — and Why It Matters

Terraform is an **infrastructure as code** tool. Instead of clicking through the AWS console or running AWS CLI commands, you describe your infrastructure in `.tf` files and Terraform creates, updates, or destroys resources to match that description.

The key property that makes Terraform powerful is **declarative intent**: you describe _what_ you want, not _how_ to get there. Terraform figures out the steps.

```hcl
# You write this:
resource "aws_s3_bucket" "infra" {
  bucket = "sca-dev-infra"
}

# Terraform figures out:
# 1. Does this bucket exist?
# 2. If not, create it.
# 3. If yes and it matches, do nothing.
# 4. If yes and it differs, update it.
```

This matters because infrastructure managed through the console is invisible — you cannot review it, version it, or reproduce it exactly. Infrastructure managed through Terraform is code: it lives in Git, goes through pull requests, and can be applied to any environment identically.

---

## How Terraform Works

### The Core Loop

Every Terraform workflow follows the same three steps:

```
terraform init    # Download providers and modules
terraform plan    # Preview what will change
terraform apply   # Apply the changes
```

**`terraform init`** sets up the working directory. It downloads the AWS provider (the library that knows how to talk to AWS) and resolves module references. You run this once when you clone the repo, and again whenever you add a new module or change provider versions.

**`terraform plan`** compares your `.tf` files against the current state of your infrastructure and produces a diff. Nothing changes in AWS. Think of it as a dry run. Always review the plan before applying.

**`terraform apply`** executes the plan. It creates, modifies, or destroys resources in AWS to match your configuration.

### State

Terraform keeps track of what it has created in a **state file**. This file maps your `.tf` resources to real AWS resource IDs. Without state, Terraform would not know whether a resource already exists or needs to be created.

In this repository, state is stored remotely in S3 with DynamoDB locking — set up by the `bootstrap/` layer. This means multiple team members can run Terraform safely without overwriting each other's state.

```hcl
backend "s3" {
  bucket         = "tf-state-sca-2026-9xk2"
  key            = "dev/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-locks"
  encrypt        = true
}
```

When one person runs `terraform apply`, DynamoDB acquires a lock. No one else can apply until the lock is released. This prevents race conditions and state corruption.

### Providers

A provider is a plugin that knows how to interact with a specific API. This repository uses the AWS provider:

```hcl
required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.38"
  }
}
```

The `~> 6.38` constraint means "accept any 6.x version >= 6.38, but not 7.x". This gives you automatic patch updates without risking breaking changes from a major version bump.

### The Plan Output

When you run `terraform plan`, every resource shows one of these symbols:

| Symbol | Meaning                         |
| ------ | ------------------------------- |
| `+`    | Will be created                 |
| `-`    | Will be destroyed               |
| `~`    | Will be modified in place       |
| `-/+`  | Will be destroyed and recreated |
| `<=`   | Will be read (data source)      |

Always pay attention to `-/+`. Recreating a resource means downtime for stateful services like databases.

---

## Repository Structure

```
.
├── bootstrap/                  # Run once — creates the S3 bucket and DynamoDB table for remote state
│   ├── main.tf
│   └── terraform.tfvars
├── environments/
│   └── dev/                    # Development environment — calls all modules
│       ├── main.tf             # Module calls and wiring
│       ├── outputs.tf          # Values exposed after apply
│       ├── variables.tf        # Input declarations
│       └── terraform.tfvars    # Actual values for this environment
└── modules/                    # Reusable building blocks
    ├── vpc/                    # Network foundation
    ├── security-groups/        # Network access rules
    ├── iam/                    # Roles and permissions
    ├── s3/                     # Object storage
    ├── ssm/                    # Session Manager configuration
    ├── kong/                   # API Gateway (EC2)
    ├── postgresql/             # SQL database (EC2)
    ├── redis/                  # Cache (EC2)
    ├── vault/                  # Secrets management (EC2)
    ├── rabbitmq/               # Message queue (EC2)
    ├── kafka/                  # Event streaming (EC2)
    ├── mongodb/                # Document store (EC2)
    ├── consul/                 # Service discovery (EC2)
    ├── observability/          # Metrics + logs + traces (EC2)
    ├── n8n/                    # Workflow automation (EC2)
    ├── sqs/                    # Managed message queues
    ├── kinesis/                # Managed event streaming
    ├── cloudwatch/             # Infrastructure alarms
    ├── secrets-manager/        # Managed secrets storage
    ├── ssm-parameters/         # Managed service discovery
    ├── rds/                    # Managed PostgreSQL (commented out)
    ├── elasticache/            # Managed Redis (commented out)
    └── documentdb/             # Managed MongoDB (commented out)
```

---

## Module Design Philosophy

Each module in this repository is a self-contained unit of infrastructure. A module owns its resources, exposes only what other modules need, and hides everything else.

### Why Modules Instead of One Big File

Without modules, all resources live in a single file. At 10 resources this is manageable. At 131 resources (the current plan for this repository) it becomes impossible to navigate, impossible to test in isolation, and impossible to reuse across environments.

Modules solve this by creating a boundary. The `postgresql` module knows how to create a PostgreSQL EC2 instance with its security group and EBS volume. The environment does not know or care about the internal structure — it only passes inputs and receives outputs.

```hcl
# The environment calls the module like a function
module "postgresql_infra" {
  source = "../../modules/postgresql"

  project               = var.project
  environment           = var.environment
  name                  = "infra"
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.private_subnet_ids[0]
  instance_profile_name = module.iam.ec2_base_instance_profile_name
  internal_sg_id        = module.security_groups.internal_sg_id
  ssm_sg_id             = module.security_groups.ssm_sg_id
  instance_type         = "t3.small"
  data_volume_size      = 50
}
```

The same `postgresql` module is called twice — once for the infra database and once for the app database — with different inputs each time. No code duplication.

### Naming Convention

Every resource in this repository follows the same naming pattern:

```
{project}-{environment}-{service}-{resource_type}

Examples:
  sca-dev-kong-ec2
  sca-dev-sg-postgresql
  sca-dev-vault-data-volume
  sca-dev-events-dlq
```

This makes it immediately clear in the AWS console what a resource belongs to and what environment it is in.

### Tagging Strategy

Every resource carries the same set of tags:

```hcl
tags = {
  Project     = "sca"
  Environment = "dev"
  Service     = "kong"
  ManagedBy   = "terraform"
  Owner       = "infra"
}
```

These tags enable AWS Cost Explorer to break down spending by service or environment, and make it trivial to find all resources belonging to a specific service.

---

## Why Variables

Variables make modules reusable and environments configurable without touching module code.

### Three Kinds of Variables in This Repository

**Input variables** — declared in `variables.tf`, passed in by the caller:

```hcl
variable "instance_type" {
  description = "EC2 instance type. Start with t3.small; upgrade when metrics show pressure."
  type        = string
  default     = "t3.small"
}
```

**Local values** — computed inside a module, not exposed outside:

```hcl
locals {
  prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

**Terraform variables file** — actual values for a specific environment:

```hcl
# environments/dev/terraform.tfvars
project     = "sca"
environment = "dev"
aws_region  = "us-east-1"
```

### Sensitive Variables

Passwords and secrets are marked `sensitive = true`. Terraform redacts them from plan output and logs:

```hcl
variable "vault_db_password" {
  description = "Password for the Vault database user in PostgreSQL."
  type        = string
  sensitive   = true
}
```

**Never commit `terraform.tfvars` files with real passwords to version control.** The `.gitignore` in this repository already excludes `*.tfvars`.

### Validation

Critical variables include validation blocks that catch bad values before Terraform attempts to apply:

```hcl
variable "retention_hours" {
  type    = number
  default = 24

  validation {
    condition     = var.retention_hours >= 24 && var.retention_hours <= 8760
    error_message = "retention_hours must be between 24 and 8760."
  }
}
```

---

## Why Outputs

Outputs serve two purposes: they expose values from a module to its caller, and they display useful information after `terraform apply` completes.

### Chaining Modules Together

The VPC module creates subnets and outputs their IDs. The PostgreSQL module needs a subnet ID to place its EC2 instance. The environment wires them together:

```hcl
# vpc module creates the subnet and outputs its ID
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

# environment passes that output to postgresql as an input
module "postgresql_infra" {
  subnet_id = module.vpc.private_subnet_ids[0]
}
```

Without outputs, every module would need to look up resources using data sources, which is slower and more fragile.

### What You See After Apply

After `terraform apply`, the environment surfaces the values you actually need:

```
Outputs:

kong_public_ip                 = "54.123.45.67"
vault_private_ip               = "10.0.11.34"
ssm_parameter_names            = {
  "kafka-private-ip"           = "/sca/dev/kafka-private-ip"
  "postgresql-infra-private-ip" = "/sca/dev/postgresql-infra-private-ip"
  ...
}
secret_names                   = {
  "vault_db_password"          = "sca-dev/vault_db_password"
  "kong_db_password"           = "sca-dev/kong_db_password"
}
```

Point your DNS at `kong_public_ip`. Use `vault_private_ip` in your Vault configuration. Retrieve service IPs from SSM Parameter Store at the paths shown in `ssm_parameter_names`.

---

## Prerequisites

### Required Tools

**Terraform >= 1.10.0**

```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install terraform

# Verify
terraform version
```

**AWS CLI >= 2.0**

```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
```

**Docker >= 24.0 and Docker Compose plugin**

Docker is not used by Terraform directly, but it is required for the configuration management layer (Ansible) that runs on top of this infrastructure. Each EC2 instance runs its service inside a Docker container.

```bash
# macOS
brew install --cask docker

# Linux (Ubuntu / Debian)
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify
docker --version
docker compose version
```

### AWS Configuration

Create a dedicated AWS CLI profile for Terraform. This isolates its credentials from your default profile and makes it easy to switch between accounts:

```bash
aws configure --profile terraform
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region name: us-east-1
# Default output format: json
```

The IAM user or role behind this profile needs the following permissions to apply this repository: `EC2FullAccess`, `S3FullAccess`, `IAMFullAccess`, `VPCFullAccess`, `SQSFullAccess`, `CloudWatchFullAccess`, `SecretsManagerFullAccess`, `SSMFullAccess`, `KinesisFullAccess`, `DynamoDBFullAccess`.

In production, scope these down to the minimum required actions. For initial setup, the above is practical.

### Session Manager Plugin (No SSH Required)

This repository uses AWS Systems Manager Session Manager instead of SSH for accessing EC2 instances. There are no key pairs, no bastion hosts, and no open port 22. Install the Session Manager plugin:

```bash
# macOS
brew install --cask session-manager-plugin

# Linux
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb

# Verify
session-manager-plugin
```

---

## Quick Start

### Step 1 — Bootstrap Remote State

The bootstrap layer creates the S3 bucket and DynamoDB table that store Terraform state. This runs once, before anything else.

```bash
cd bootstrap/
terraform init
terraform plan
terraform apply
```

Expected output:

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
  state_bucket_name    = "tf-state-sca-2026-9xk2"
  dynamodb_table_name  = "terraform-locks"
```

### Step 2 — Configure the Environment

Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values:

```bash
cd environments/dev/
cp terraform.tfvars.example terraform.tfvars
```

```hcl
project           = "sca"
environment       = "dev"
aws_region        = "us-east-1"
aws_profile       = "terraform"
vault_db_password = "choose-a-strong-password"
```

> **Never commit `terraform.tfvars` to version control.** It is already in `.gitignore`.

### Step 3 — Initialize and Plan

```bash
terraform init
terraform plan
```

Review the plan carefully. You should see `131 to add, 0 to change, 0 to destroy`. Any destroy operations on a fresh environment are unexpected and should be investigated before applying.

### Step 4 — Apply

```bash
terraform apply
```

Type `yes` when prompted. The apply takes approximately 5–10 minutes. EC2 instances, VPC endpoints, and IAM resources are the slowest to provision.

### Step 5 — Access an Instance

Once apply completes, use Session Manager to open a shell on any instance:

```bash
# Get the instance ID from terraform output
terraform output kong_instance_id

# Open a session
aws ssm start-session --target i-0abc123def456 --profile terraform
```

No key pair. No security group rule for port 22. Full audit trail in CloudWatch Logs.

---

## Expected Behavior After Apply

After a successful `terraform apply`, you should observe:

**In the AWS Console:**

- 1 VPC with 2 public and 2 private subnets across 2 AZs
- 12 EC2 instances in the private subnets (except Kong, which is in the public subnet)
- 1 Elastic IP attached to the Kong instance
- 4 VPC endpoints (SSM, SSM Messages, EC2 Messages, S3)
- 2 SQS queues and 2 dead-letter queues
- 2 Kinesis streams in ON_DEMAND mode
- 24 CloudWatch Alarms (2 per EC2 instance + 2 for SQS DLQs)
- 2 Secrets Manager secrets
- 12 SSM Parameter Store parameters
- All EC2 instances reachable via Session Manager

**What is not yet running:**
The EC2 instances are provisioned with a clean Ubuntu AMI. No software is installed yet. Kafka, PostgreSQL, Vault, and the other services require a configuration management step (Ansible) after infrastructure provisioning.

---

## Cost Estimates

All estimates are for `us-east-1` running 24/7 for a full month. Prices reflect on-demand rates as of 2025.

### EC2 Instances

| Instance         | Type      | Monthly Cost    |
| ---------------- | --------- | --------------- |
| Kong             | t3.small  | ~$15            |
| PostgreSQL infra | t3.small  | ~$15            |
| PostgreSQL app   | t3.small  | ~$15            |
| Redis            | t3.small  | ~$15            |
| Vault            | t3.small  | ~$15            |
| RabbitMQ         | t3.small  | ~$15            |
| Kafka            | t3.medium | ~$30            |
| MongoDB          | t3.small  | ~$15            |
| Consul           | t3.small  | ~$15            |
| Observability    | t3.small  | ~$15            |
| n8n infra        | t3.small  | ~$15            |
| n8n app          | t3.small  | ~$15            |
| **EC2 Total**    |           | **~$190/month** |

### EBS Volumes

| Volume                            | Size  | Monthly Cost   |
| --------------------------------- | ----- | -------------- |
| Root volumes × 12 (20GB gp3 each) | 240GB | ~$19           |
| PostgreSQL infra data             | 50GB  | ~$4            |
| PostgreSQL app data               | 50GB  | ~$4            |
| Vault data                        | 20GB  | ~$1.60         |
| RabbitMQ data                     | 30GB  | ~$2.40         |
| Kafka data                        | 50GB  | ~$4            |
| MongoDB data                      | 50GB  | ~$4            |
| Observability data                | 50GB  | ~$4            |
| **EBS Total**                     |       | **~$43/month** |

### Managed Services

| Service                    | Configuration                   | Monthly Cost    |
| -------------------------- | ------------------------------- | --------------- |
| SQS                        | 2 queues + 2 DLQs, low volume   | ~$0 (Free Tier) |
| Kinesis                    | 2 ON_DEMAND streams, low volume | ~$0–$2          |
| CloudWatch Alarms          | 24 alarms                       | ~$2.40          |
| Secrets Manager            | 2 secrets                       | ~$0.80          |
| SSM Parameter Store        | 12 Standard parameters          | ~$0 (Free)      |
| **Managed Services Total** |                                 | **~$5/month**   |

### Networking

| Resource                    | Monthly Cost |
| --------------------------- | ------------ | -------------- |
| Elastic IP (Kong)           | ~$3.60       |
| VPC Interface Endpoints × 3 | ~$21         |
| S3 Gateway Endpoint         | ~$0          |
| Data transfer (low volume)  | ~$2          |
| **Networking Total**        |              | **~$27/month** |

### Total Estimated Cost

| Layer            | Monthly         |
| ---------------- | --------------- |
| EC2              | ~$190           |
| EBS              | ~$43            |
| Managed services | ~$5             |
| Networking       | ~$27            |
| **Grand Total**  | **~$265/month** |

> **Cost reduction opportunities:** Switch to Reserved Instances after 3 months of stable usage to cut EC2 costs by ~40% (~$76/month savings). Stop non-critical instances (n8n, observability, consul) outside working hours during early development to reduce costs further.

### Managed AWS Failover Cost (if activated)

| Service                    | Replaces           | Monthly Cost              |
| -------------------------- | ------------------ | ------------------------- |
| RDS db.t3.micro            | PostgreSQL EC2 × 2 | ~$15 (Free Tier eligible) |
| ElastiCache cache.t3.micro | Redis EC2          | ~$12                      |
| DocumentDB db.t3.medium    | MongoDB EC2        | ~$65                      |

---

## Managed AWS Services — Failover Layer

This repository includes three fully built modules that are commented out in `environments/dev/main.tf`. They exist for two scenarios: cost reduction at very low traffic (managed services can be cheaper than running EC2 instances 24/7), and operational simplicity when the team does not want to manage backups, patches, and failover manually.

### Activating a Managed Service

To activate RDS as a replacement for the PostgreSQL EC2 instances:

1. Add the required variable to `environments/dev/variables.tf`:

```hcl
variable "rds_master_password" {
  description = "Master password for the RDS instance."
  type        = string
  sensitive   = true
}
```

2. Add the value to `terraform.tfvars`:

```hcl
rds_master_password = "choose-a-strong-password"
```

3. Uncomment the module block in `environments/dev/main.tf`:

```hcl
module "rds" {
  source = "../../modules/rds"
  ...
}
```

4. Uncomment the outputs in `environments/dev/outputs.tf`.

5. Run `terraform plan` and review, then `terraform apply`.

### Choosing Between Self-Hosted and Managed

| Factor               | Self-Hosted EC2                              | AWS Managed                          |
| -------------------- | -------------------------------------------- | ------------------------------------ |
| Fixed monthly cost   | Yes — EC2 runs 24/7                          | Varies — pay for what you use        |
| Operational burden   | High — you manage patches, backups, failover | Low — AWS handles it                 |
| Customization        | Full control                                 | Limited to provider options          |
| Failover             | Manual                                       | Automatic (Multi-AZ)                 |
| Right time to switch | Never, or when ops burden is felt            | When team feels the maintenance pain |

---

## Glossary

**Backend** — Where Terraform stores its state file. This repository uses S3 as the backend with DynamoDB for locking.

**Data Source** — A read-only reference to an existing resource not managed by this Terraform configuration. Example: `data.aws_caller_identity.current` reads the AWS account ID without creating anything.

**Dead-Letter Queue (DLQ)** — A secondary SQS queue that receives messages that failed processing after a configurable number of attempts. Used to catch failures silently and inspect them later.

**EBS Volume** — Elastic Block Store. A persistent disk that attaches to an EC2 instance. In this repository, every stateful service (databases, Kafka, Vault) has a separate EBS volume for data, distinct from the root volume. If the EC2 instance is replaced, the data volume survives.

**Environment** — A deployment target with its own set of resources and its own Terraform state. This repository has a `dev` environment. Adding `staging` or `prod` means creating a new directory under `environments/` with the same structure.

**for_each** — A Terraform meta-argument that creates one resource instance per element in a map or set. Used in this repository to create multiple SQS queues, Kinesis streams, CloudWatch alarms, and SSM parameters from a single resource block.

**IAM Instance Profile** — The mechanism that gives an EC2 instance a set of AWS permissions. Without an instance profile, an EC2 instance cannot call any AWS API. In this repository, all instances receive a base profile with SSM and S3 access.

**Idempotent** — An operation that produces the same result regardless of how many times it is applied. Terraform is idempotent: running `terraform apply` twice in a row with no changes results in no changes on the second run.

**KRaft** — Kafka's built-in consensus protocol, introduced as a replacement for ZooKeeper. The Kafka module in this repository uses KRaft mode, which means no ZooKeeper dependency and simpler single-node operation.

**Locals** — Computed values defined inside a module using a `locals {}` block. They cannot be overridden from outside the module and are used to avoid repeating expressions like `"${var.project}-${var.environment}"`.

**Module** — A directory containing `.tf` files that can be called from another Terraform configuration. Modules accept inputs (variables) and expose outputs. They are the primary unit of reuse in Terraform.

**ON_DEMAND (Kinesis)** — A Kinesis stream mode where AWS automatically scales capacity based on traffic. You pay per GB ingested and read rather than per shard-hour. Cheaper than PROVISIONED at low and unpredictable volumes.

**Output** — A value that a module exposes to its caller, or that an environment exposes after `terraform apply`. Outputs are the mechanism by which modules share information with each other.

**Provider** — A plugin that enables Terraform to interact with a specific API. This repository uses the AWS provider (`hashicorp/aws`), which knows how to create and manage AWS resources.

**Remote State** — Terraform state stored outside the local machine, in S3 in this case. Enables team collaboration and prevents state loss if a developer's machine is lost or wiped.

**Security Group** — A virtual firewall for EC2 instances and other AWS resources. It controls which traffic is allowed in (ingress rules) and out (egress rules). In this repository, every service has its own security group defining exactly which ports it accepts connections on.

**Sensitive** — A Terraform attribute that prevents a value from appearing in plan output, logs, and state display. Passwords and tokens are marked sensitive. Note: the value is still stored in state — use encryption and restricted access on the state bucket.

**Session Manager** — An AWS Systems Manager feature that allows shell access to EC2 instances without SSH, key pairs, or open inbound ports. All access is logged to CloudWatch. This repository uses Session Manager exclusively for instance access.

**shard (Kinesis)** — The unit of parallelism in a Kinesis stream. Each shard handles 1 MB/s write and 2 MB/s read. In ON_DEMAND mode, shards scale automatically. In PROVISIONED mode, you specify the count and pay per shard-hour.

**SSM Parameter Store** — An AWS service for storing configuration values as key-value pairs. This repository uses it to store the private IP of every EC2 instance, enabling applications to discover services without hardcoded IPs.

**State Lock** — A mechanism that prevents two Terraform processes from modifying state simultaneously. This repository uses DynamoDB for locking: when `terraform apply` starts, it acquires a lock; when it finishes, it releases it.

**t3 Instance Family** — AWS burstable instances with CPU credit system. They run at a baseline CPU level and accumulate credits when idle. Credits are spent during CPU bursts. When credits run out, performance is throttled. CloudWatch alarms in this repository monitor CPU credit balance to detect instances under sustained pressure.

**Terraform Registry** — The public repository of Terraform providers and modules at `registry.terraform.io`. The AWS provider used in this repository comes from there.

**User Data** — A script that runs once when an EC2 instance first boots. In this repository, user data is minimal — full service configuration is handled by Ansible after provisioning.

**VPC Endpoint** — A private connection between your VPC and an AWS service that keeps traffic inside the AWS network, without requiring an internet gateway. This repository creates endpoints for SSM, SSM Messages, EC2 Messages, and S3 — required for Session Manager to work without a NAT gateway.
