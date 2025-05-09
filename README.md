# IaC-meets-CICD
Automating cloud resource deployment using Terraform as IaC and Github Actions

## about this project
- GitHub Actions CI/CD pipeline for Terraform-based AWS infrastructure deployment
- Secure AWS authentication via OIDC federation (no static credentials)
- Self-hosted GitHub runners on EC2 for isolated execution environments
- Terraform-managed runner infrastructure (VPC, networking, security groups)
- Ansible-configured runners with automated registration and systemd service setup
- Event-driven workflow triggers on infrastructure code changes
- Temporary AWS credentials via AssumeRoleWithWebIdentity
- S3 remote backend with state locking for Terraform operations

![img](https://github.com/luffyxxsenpai/IaC-meets-CICD/blob/main/final.svg)


## infra_setup_terraform
- Desired Infrastructure Core Components:
   - VPC with CIDR 10.0.0.0/16
   - Multi-AZ network architecture
    -    2 public subnets (10.0.1.0/24, 10.0.2.0/24)
    -    2 private subnets (10.0.3.0/24, 10.0.4.0/24)
   - High availability design
    -    2 NAT gateways (1 per AZ)
    -    2 Elastic IP allocations
    -    1 Internet Gateway
    -    AZ-specific route tables
    - Restricted security group rules:
     -    Ingress: TCP 22 (SSH), 80/443 (HTTP/HTTPS)
     -   Egress: Ephemeral ports (1024-65535)

## runner_ansible_setup
- Self-hosted GitHub Runner deployment on EC2
- Node.js (LTS) + essential tools (curl, git, unzip, jq) installation
- Secure GitHub API token fetch via POST request
- Dedicated ubuntu user with restricted permissions
- Runner binary download and automated registration
- Systemd service setup for auto-start and management
- AWS dynamic inventory targeting runner-tagged EC2 instances

## runner_infra_setup
- VPC with isolated public subnet for runners
- Internet Gateway for controlled external access
- Security Group with restricted SSH ingress (port 22)
- Route tables for public subnet traffic routing
- EC2 instances pre-configured for Ansible execution
- S3 backend for secure Terraform state storage

## project structure
```bash
IaC-meets-CICD main*​​​ 󱍢 tree .                          
.
├── final.svg
├── infra_setup_terraform
│   ├── main.tf
│   ├── module
│   │   └── vpc
│   │       ├── 1-variable.tf
│   │       ├── 2-vpc.tf
│   │       ├── 3-subnet.tf
│   │       ├── 4-gateways.tf
│   │       ├── 5-routes.tf
│   │       └── 6-sg.tf
│   └── provider.tf
├── LICENSE
├── README.md
├── runner_ansible_setup
│   ├── aws_ec2.yml
│   ├── group_vars
│   │   └── runner.yaml
│   └── runner_play.yaml
└── runner_infra_setup_terraform
    ├── main.tf
    ├── module
    │   └── vpc-ec2
    │       ├── 1-variable.tf
    │       ├── 2-vpc.tf
    │       ├── 3-subnet.tf
    │       ├── 4-gateways.tf
    │       ├── 5-routes.tf
    │       ├── 6-sg.tf
    │       ├── 7-ec2.tf
    │       └── 8-data.tf
    └── provider.tf

9 directories, 24 files
```

## AWS OIDC
- how to setup aws oidc for github
- create a identity provider in aws IAM for 'https://token.actions.githubusercontent.com' as provider and 'sts.amazonaws.com' as an audience

- create a role with trusted entity type as web identity and choose the github provider and rest of the information

- assign the policy you want to give (for testing you can give AdministratorAccess)
- the trurst policy will be something like this
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Principal": {
                "Federated": "arn:aws:iam::53xx12xxxx197:oidc-provider/token.actions.githubusercontent.com"
            },
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": [
                        "sts.amazonaws.com"
                    ]
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": [
                        "repo:your-github-username/your-github-repo:*"
                    ]
                }
            }
        }
    ]
}
```
- give this role a name and create it
- we will use this role arn to let github action assume this role and get a temporary (1hr) credential using aws sts.=

## GITHUB WORKFLOW YAML

```yml

on:
  push:
    branches: [ "main" ]
    paths:
      - 'infra_setup_terraform/**'
permissions:
  id-token: write   # Required for OIDC authentication
  contents: read    # Required to checkout code
jobs:
  terraform:
    name: Terraform
    runs-on: self-hosted
    environment: production
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    - name: Configure AWS Credentials via OIDC
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::537xxxxxxx7197:role/github-runner-terraform-vpc
        aws-region: ap-south-1
        role-session-name: github-terraform-session
```

- `on` specify when to trigger action which is when we commit in the `infra_setup_terraform` of main branch

- `permissions` is required for OIDC 
- ` - name: Configure AWS Credentials via OIDC` this sections specify which role to assume from aws which later will be used in pipeline
- after that we specify all the steps or stages we want to have in our pipeline