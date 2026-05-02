# AWS Multi-Environment Infrastructure with Terraform

## 📌 Overview

This project demonstrates how to design and deploy a modular, multi-environment AWS infrastructure using Terraform.

The system supports Dev and Production environments from a single codebase, using:
- Reusable Terraform modules  
- Remote state management (S3 + DynamoDB)  
- Environment-specific configurations (.tfvars)  
- Conditional logic for scalable infrastructure  

---

## 🏗 Architecture

### 🔁 Request Flow

text User → Internet → Internet Gateway → Route Table → Public Subnet → EC2 Instance (ASG) → Web Server 

### 🧠 Key Components

- VPC: Isolated network environment
- Public Subnets: Hosts EC2 instances across multiple Availability Zones
- Internet Gateway (IGW): Enables internet access
- Route Table: Routes external traffic to IGW
- Security Group: Controls inbound (HTTP/SSH) and outbound traffic
- Launch Template: Defines EC2 configuration
- Auto Scaling Group (ASG): Ensures scalability in production
- S3 Backend: Stores Terraform state remotely
- DynamoDB Table: Handles state locking

---

## ⚙️ Tech Stack

- Terraform (Infrastructure as Code)
- AWS EC2 (Compute)
- AWS VPC (Networking)
- AWS Auto Scaling (Scalability)
- AWS S3 (Remote State Storage)
- AWS DynamoDB (State Locking)
- Amazon Linux 2023 (OS)
- Bash (User Data Scripts) (Provisioning)

---

# 🧩 Step-by-Step Implementation

This section breaks down exactly how the infrastructure was built.

---

## 🔹 Step 1: Project Structure Setup

We organized the project using a modular architecture:

bash modules/   ├── vpc/   ├── ec2/   └── security/  environments/   ├── dev/   └── prod/  main.tf variables.tf backend.tf 

### Why this matters:
- Promotes reusability
- Avoids duplication (DRY principle)
- Mirrors real-world DevOps projects

---

## 🔹 Step 2: Remote Backend Configuration

Instead of storing state locally, we configured:

- S3 bucket → Terraform state storage  
- DynamoDB table → state locking  

hcl terraform {   backend "s3" {     bucket         = "my-company-terraform-state"     key            = "terraform.tfstate"     region         = "us-east-1"     dynamodb_table = "terraform-lock-table"     encrypt        = true   } } 

### Why this matters:
- Prevents state loss
- Enables team collaboration
- Avoids concurrent state corruption

---

## 🔹 Step 3: VPC Module (Networking Foundation)

We created a reusable VPC module:

### Key resources:
- VPC
- Subnets (dynamic using count)
- Internet Gateway
- Route Table
- Route Table Association

hcl resource "aws_subnet" "public" {   count = length(var.public_subnets)    vpc_id                  = aws_vpc.this.id   cidr_block              = var.public_subnets[count.index]   availability_zone       = data.aws_availability_zones.available.names[count.index]   map_public_ip_on_launch = true } 

### Key concept:
- count dynamically creates subnets based on environment

---

## 🔹 Step 4: Security Module

Defined a reusable Security Group:

hcl resource "aws_security_group" "web_sg" {   vpc_id = var.vpc_id    ingress {     from_port   = 80     to_port     = 80     protocol    = "tcp"     cidr_blocks = ["0.0.0.0/0"]   }    ingress {     from_port   = 22     to_port     = 22     protocol    = "tcp"     cidr_blocks = ["0.0.0.0/0"]   }    egress {     from_port   = 0     to_port     = 0     protocol    = "-1"     cidr_blocks = ["0.0.0.0/0"]   } } 

### Key lesson:
- Missing egress rules can completely block outbound traffic

---

## 🔹 Step 5: EC2 + Auto Scaling Module

We used a Launch Template and conditional Auto Scaling:

hcl resource "aws_launch_template" "web" {   image_id      = var.ami   instance_type = var.instance_type    vpc_security_group_ids = [var.sg_id]    user_data = base64encode(file("${path.module}/user_data.sh")) } 

### Auto Scaling (Prod only):

hcl resource "aws_autoscaling_group" "web" {   count = var.enable_asg ? 1 : 0 } 

### Key concept:
- Conditional logic differentiates Dev vs Prod

---

## 🔹 Step 6: Environment Configuration

### Dev (dev.tfvars)

hcl instance_type = "t3.micro" enable_asg    = false 

### Prod (prod.tfvars)

hcl instance_type = "t3.large" enable_asg    = true 

### Result:
- Same codebase → different infrastructure behavior

---

## 🔹 Step 7: Workspaces

bash terraform workspace new dev terraform workspace new prod 

### Why:
- Isolates environments logically

---

## 🔹 Step 8: Deployment Workflow

bash terraform init terraform workspace select dev terraform plan -var-file="environments/dev/dev.tfvars" terraform apply -var-file="environments/dev/dev.tfvars" 

Repeat for production.

---

# ⚠️ Challenges & Solutions

---

## ❌ Challenge 1: EC2 had no internet access

### Symptoms:
- curl hangs
- dnf install fails
- Browser not loading

### Root Causes:
- Missing route to IGW
- Subnet misconfiguration
- Missing security group egress

### ✅ Solution:
- Added route 0.0.0.0/0 → IGW
- Enabled map_public_ip_on_launch
- Added outbound rule in security group

---

## ❌ Challenge 2: Terraform State Lock Errors

### Error:
text Error acquiring the state lock 

### Cause:
- Interrupted Terraform execution

### ✅ Solution:
bash terraform force-unlock <LOCK_ID> 

---

## ❌ Challenge 3: Resources Not Updating

### Cause:
- Terraform not detecting changes in ASG

### ✅ Solution:
bash terraform apply -replace="module.ec2.aws_autoscaling_group.web[0]" 

---

## ❌ Challenge 4: AMI Issues

### Cause:
- Invalid or outdated AMI ID

### Solution:
- Use valid AMI or data source

---

## ❌ Challenge 5: Launch Template Networking Issues

### Cause:
- Misuse of network_interfaces

### Solution:
- Use vpc_security_group_ids instead

---

# 🧠 Key Takeaways

- Infrastructure debugging requires layer-by-layer isolation
- Networking issues are often multi-factor problems
- Terraform state management is critical for reliability
- Modular design enables scalability and reuse
- Dev and Prod should NEVER share state

---

# 🚀 Future Improvements

- Add Application Load Balancer (ALB)
- Implement CI/CD (GitHub Actions)
- Add monitoring (CloudWatch)
- Use dynamic AMI lookup
- Introduce HTTPS (ACM)

---

# 👤 Author

*Samuel Tettey-Fio
