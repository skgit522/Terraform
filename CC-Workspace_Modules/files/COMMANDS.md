# Lab execution guide — workspaces + modules

## Folder structure you should have

```
CC-ABV-Lab-1/
├── backend-bootstrap/
│   └── main.tf              ← run once only
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── sg/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── s3/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf                  ← calls all modules
├── variables.tf
├── outputs.tf
└── versions.tf              ← has S3 backend config
```

---

## Step 1 — verify credentials

```bash
aws sts get-caller-identity --profile sk-tf
# must return your AccountId before proceeding
```

---

## Step 2 — bootstrap the backend (run once only)

```bash
cd backend-bootstrap
terraform init
terraform plan
terraform apply
cd ..
```

Expected output:
```
state_bucket_name   = "sk-tf-state-bucket"
dynamodb_table_name = "sk-tf-state-lock"
```

---

## Step 3 — initialize root project with remote backend

```bash
# back in root lab folder
terraform init
```

Terraform will connect to the S3 bucket and confirm the backend.

---

## Step 4 — create the three workspaces

```bash
# workspaces must be created before you can select them
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# confirm all three exist
terraform workspace list
# output:
#   default
#   dev
# * staging   ← currently active (whichever you created last)
#   prod
```

---

## Step 5 — deploy dev environment

```bash
terraform workspace select dev
terraform workspace show        # confirms: dev

terraform plan -out=tfplan
terraform apply tfplan

# expected outputs:
# active_workspace    = "dev"
# alb_dns_name        = "sk-tf-dev-alb-xxxx.ap-south-1.elb.amazonaws.com"
# instance_ids        = ["i-xxx"]          ← 1 instance
# s3_bucket_name      = "sk-tf-dev-app-bucket"
```

---

## Step 6 — deploy staging environment

```bash
terraform workspace select staging
terraform workspace show        # confirms: staging

terraform plan -out=tfplan
terraform apply tfplan

# expected outputs:
# active_workspace    = "staging"
# alb_dns_name        = "sk-tf-staging-alb-xxxx.ap-south-1.elb.amazonaws.com"
# instance_ids        = ["i-xxx", "i-yyy"]  ← 2 instances
# s3_bucket_name      = "sk-tf-staging-app-bucket"
```

---

## Step 7 — deploy prod environment

```bash
terraform workspace select prod
terraform workspace show        # confirms: prod

terraform plan -out=tfplan
terraform apply tfplan

# expected outputs:
# active_workspace    = "prod"
# alb_dns_name        = "sk-tf-prod-alb-xxxx.ap-south-1.elb.amazonaws.com"
# instance_ids        = ["i-aaa","i-bbb","i-ccc","i-ddd"]  ← 4 instances
# s3_bucket_name      = "sk-tf-prod-app-bucket"
```

---

## Verifying state files are separate

```bash
# list state files in S3 — you should see one per workspace
aws s3 ls s3://sk-tf-state-bucket/env:/ --recursive --profile sk-tf

# output:
# env:/dev/terraform.tfstate
# env:/staging/terraform.tfstate
# env:/prod/terraform.tfstate
```

---

## Tearing down (in reverse order — always destroy before switching)

```bash
# destroy prod first
terraform workspace select prod
terraform destroy

# destroy staging
terraform workspace select staging
terraform destroy

# destroy dev
terraform workspace select dev
terraform destroy

# destroy backend last (only when completely done with the lab)
cd backend-bootstrap
terraform destroy
```

---

## Key workspace commands cheatsheet

```bash
terraform workspace list          # show all workspaces
terraform workspace show          # show currently active workspace
terraform workspace new dev       # create a new workspace
terraform workspace select prod   # switch to prod workspace
terraform workspace delete dev    # delete a workspace (must be empty)
```
