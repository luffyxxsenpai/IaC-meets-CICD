# IaC meets CI/CD

End-to-end automated AWS infrastructure deployment using Terraform as IaC and GitHub Actions as the CI/CD pipeline — with zero static credentials, self-hosted runners, and full Ansible-based runner provisioning.

---

## What This Project Does

Push code to `infra_setup_terraform/` → GitHub Actions triggers → self-hosted EC2 runner picks up the job → assumes an AWS IAM role via OIDC (no hardcoded keys) → runs `terraform plan` + `terraform apply` → infrastructure is live.

The runner itself is also fully automated: Terraform provisions the EC2 instance, Ansible configures it, registers it as a GitHub runner, and sets it up as a systemd service.

---

## Architecture

```
Developer pushes to main
        │
        ▼
GitHub Actions Workflow
  (id-token: write → OIDC token)
        │
        ▼  AssumeRoleWithWebIdentity
AWS STS → Temporary credentials (1hr)
        │
        ▼
Self-hosted EC2 Runner
  (terraform init → plan → apply)
        │
        ▼
Target AWS Infrastructure (VPC, subnets, NAT, IGW, SGs)
```

```
┌──────────────────────────────────────────────┐
│              GitHub Actions                  │
│  Trigger: push to infra_setup_terraform/     │
│  Auth: OIDC → AssumeRoleWithWebIdentity      │
│  Runner: self-hosted (EC2)                   │
└──────────────────┬───────────────────────────┘
                   │
       ┌───────────┴─────────────┐
       ▼                         ▼
Runner Infrastructure       Target Infrastructure
(runner_infra_setup_tf)     (infra_setup_terraform)
  VPC + EC2 + SG               VPC Module
       │                       Multi-AZ subnets
       ▼                       NAT Gateways
Ansible Playbook               Security Groups
  Install runner binary         S3 Remote State
  Register to repo
  Setup systemd service
```

---

## Project Structure

```
IaC-meets-CICD/
├── .github/
│   └── workflows/
│       └── terraform.yml           # GitHub Actions pipeline
├── infra_setup_terraform/
│   ├── main.tf                     # Root module calling vpc module
│   ├── provider.tf                 # AWS provider + S3 backend
│   └── module/
│       └── vpc/
│           ├── 1-variable.tf
│           ├── 2-vpc.tf
│           ├── 3-subnet.tf
│           ├── 4-gateways.tf
│           ├── 5-routes.tf
│           └── 6-sg.tf
├── runner_infra_setup_terraform/
│   ├── main.tf
│   ├── provider.tf
│   └── module/
│       └── vpc-ec2/
│           ├── 1-variable.tf
│           ├── 2-vpc.tf
│           ├── 3-subnet.tf
│           ├── 4-gateways.tf
│           ├── 5-routes.tf
│           ├── 6-sg.tf
│           ├── 7-ec2.tf            # Runner EC2 instance
│           └── 8-data.tf           # AMI data source
└── runner_ansible_setup/
    ├── aws_ec2.yml                  # Dynamic inventory (tag: selfhosted-runner)
    ├── runner_play.yaml             # Runner setup playbook
    └── group_vars/
        └── runner.yaml             # GitHub token + repo config
```

---

## Components

### 1. Target Infrastructure (`infra_setup_terraform`)

Modular Terraform that provisions a production-grade VPC:

| Resource | Details |
|---|---|
| VPC | `10.0.0.0/16` |
| Public subnets | `10.0.1.0/24`, `10.0.2.0/24` — two AZs |
| Private subnets | `10.0.3.0/24`, `10.0.4.0/24` — two AZs |
| NAT Gateways | 1 per AZ for HA egress |
| Internet Gateway | Public subnet access |
| Route Tables | AZ-specific, separated for public/private |
| Security Group | SSH (22), HTTP/HTTPS (80/443) ingress; ephemeral ports egress |
| Remote State | S3 backend with state locking |

### 2. Runner Infrastructure (`runner_infra_setup_terraform`)

Terraform provisions the EC2 instance that runs GitHub Actions jobs:

- Isolated VPC with public subnet
- Security group — SSH-only ingress (port 22)
- EC2 instance pre-tagged `selfhosted-runner` for Ansible dynamic inventory
- S3 backend for runner state

### 3. Runner Configuration (`runner_ansible_setup`)

Ansible playbook that fully configures the EC2 instance as a GitHub runner:

- AWS EC2 dynamic inventory — auto-discovers instances tagged `selfhosted-runner`
- Installs Node.js LTS, `curl`, `git`, `unzip`, `jq`
- Creates a dedicated `ubuntu` user with restricted permissions
- Fetches a registration token from the GitHub API
- Downloads and configures the runner binary
- Registers the runner to the repository
- Installs as a `systemd` service (auto-start, survives reboots)

### 4. GitHub Actions Pipeline

```yaml
on:
  push:
    branches: ["main"]
    paths:
      - 'infra_setup_terraform/**'   # only triggers on infra changes

permissions:
  id-token: write    # required for OIDC
  contents: read

jobs:
  terraform:
    runs-on: self-hosted
    environment: production
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<account-id>:role/github-runner-terraform-vpc
          aws-region: ap-south-1
          role-session-name: github-terraform-session
      - run: terraform init && terraform plan && terraform apply -auto-approve
        working-directory: infra_setup_terraform
```

---

## AWS OIDC Setup (One-time)

This project uses OIDC federation — GitHub gets a short-lived JWT, exchanges it with AWS STS for temporary credentials. No access keys stored anywhere.

**Step 1:** Create an IAM Identity Provider in AWS

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

**Step 2:** Create an IAM Role with a web identity trust policy

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Principal": {
      "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": ["sts.amazonaws.com"]
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": [
          "repo:<your-github-username>/IaC-meets-CICD:*"
        ]
      }
    }
  }]
}
```

**Step 3:** Attach required policies to the role (VPC, EC2, S3 for Terraform state)

**Step 4:** Paste the role ARN into the workflow `role-to-assume` field

Credentials are valid for 1 hour per session. No rotation needed, no secrets to manage.

---

## Usage

### Step 1: Provision the runner EC2

```bash
cd runner_infra_setup_terraform
terraform init
terraform apply
```

### Step 2: Configure and register the runner via Ansible

```bash
cd runner_ansible_setup

# Edit group_vars/runner.yaml with your GitHub token and repo details
# Dynamic inventory auto-discovers EC2s tagged selfhosted-runner

ansible-playbook -i aws_ec2.yml runner_play.yaml
```

Verify the runner appears as **Idle** under Settings → Actions → Runners in your repo.

### Step 3: Trigger the pipeline

Make any change inside `infra_setup_terraform/` and push to `main`:

```bash
git add infra_setup_terraform/
git commit -m "update security group rules"
git push origin main
```

GitHub Actions triggers, authenticates via OIDC, and runs Terraform on your self-hosted runner.

---

## Prerequisites

- AWS account with permissions to create VPC, EC2, IAM, S3 resources
- GitHub repository with Actions enabled
- AWS CLI configured locally
- Ansible installed with `amazon.aws` collection:
  ```bash
  ansible-galaxy collection install amazon.aws
  ```
- Terraform >= 1.5
- S3 bucket already created for remote state — update `provider.tf` with your bucket name

---

## Security Model

| Concern | Approach |
|---|---|
| AWS credentials in CI | OIDC federation — no static keys, ever |
| Credential lifetime | 1-hour temporary session via `AssumeRoleWithWebIdentity` |
| Runner isolation | Self-hosted EC2 in a dedicated VPC, not GitHub shared infra |
| Terraform state | S3 with server-side encryption + state locking |
| Runner permissions | Dedicated `ubuntu` user, minimal system access |
| IAM scope | Trust policy scoped to this specific repo only |

---

## TODOs / Improvements

- [ ] Add `terraform plan` as a PR check — `apply` only on merge to main
- [ ] Add `terraform fmt` + `validate` step to pipeline
- [ ] Add `tfsec` or `checkov` for IaC security scanning
- [ ] Scope OIDC trust policy to specific branches (currently `*`)
- [ ] Add runner auto-deregistration and EC2 termination after job completion
- [ ] Move GitHub registration token out of `group_vars` and into AWS Secrets Manager





![img](https://github.com/luffyxxsenpai/IaC-meets-CICD/blob/main/img/final.svg)





![img](https://github.com/luffyxxsenpai/IaC-meets-CICD/blob/main/img/identity.png)
![img](https://github.com/luffyxxsenpai/IaC-meets-CICD/blob/main/img/identity1.png)

![img](https://github.com/luffyxxsenpai/IaC-meets-CICD/blob/main/img/role.png)


![img](https://github.com/luffyxxsenpai/IaC-meets-CICD/blob/main/img/runner.png)
