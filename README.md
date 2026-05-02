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

<img width="1536" height="1024" alt="architectural diagram" src="https://github.com/user-attachments/assets/b4249311-1802-419f-9918-15f83818c076" />


### ⚙️ Key Components

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

# 🧩 Step-by-Step Implementation

This section breaks down exactly how the infrastructure was built.

---

## 🔹 Step 1: Project Structure Setup

I organized the project using a modular architecture:

```bash
modules/
  ├── vpc/        # VPC, Subnets, Internet Gateway
  ├── ec2/        # Launch Template, Auto Scaling Group
  └── security/   # Security Groups

environments/
  ├── dev/        # Development variables
  └── prod/       # Production variables

main.tf           # Root module
variables.tf      # Input variables
backend.tf        # Remote state configuration
```

### Why this matters:
- Promotes reusability
- Avoids duplication (DRY principle)
- Mirrors real-world DevOps projects

---

## 🔹 Step 2: Remote Backend Configuration

Instead of storing state locally, I configured:

- S3 bucket → Terraform state storage  
- DynamoDB table → state locking  

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
```

### Why this matters:
- Prevents state loss
- Enables team collaboration
- Avoids concurrent state corruption

##### *Creation of S3 Bucket for Terraform state*
<img width="771" height="146" alt="Creation of S3 Bucket for Terraform state" src="https://github.com/user-attachments/assets/a8275473-9373-4a6a-b9a6-7620afe80107" />

##### *Creation of DynamoDB Table for locking*
<img width="771" height="437" alt="Creation of DynamoDB Table for locking" src="https://github.com/user-attachments/assets/b65e5a77-9383-492b-91a8-d52a9c923d14" />

##### *s3 bucket created for remote terraform state*
<img width="853" height="612" alt="s3 bucket created for remote terraform state" src="https://github.com/user-attachments/assets/0b06e938-b13b-4a64-9fc1-5e17d938d917" />

---

## 🔹 Step 3: VPC Module (Networking Foundation)

I created a reusable VPC module:

### Key resources:
- VPC
- Subnets (dynamic using count)
- Internet Gateway
- Route Table
- Route Table Association

```hcl
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}
```

### Key concept:
- count dynamically creates subnets based on environment

##### *Defining VPC resources*
<img width="988" height="938" alt="Defining VPC resources" src="https://github.com/user-attachments/assets/189006ca-e2ba-4049-9359-7661e453d7f4" />

---

## 🔹 Step 4: Security Module

Defined a reusable Security Group:

```hcl
resource "aws_security_group" "web_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Key lesson:
- Missing egress rules can completely block outbound traffic

---

## 🔹 Step 5: EC2 + Auto Scaling Module

I used a Launch Template and conditional Auto Scaling:

```hcl
resource "aws_launch_template" "web" {
  image_id      = var.ami
  instance_type = var.instance_type

  vpc_security_group_ids = [var.sg_id]

  user_data = base64encode(file("${path.module}/user_data.sh"))
}
```

### Auto Scaling (Prod only):

```hcl
resource "aws_autoscaling_group" "web" {
  count = var.enable_asg ? 1 : 0
}
```

### Key concept:
- Conditional logic differentiates Dev vs Prod

##### *ec2 module main tf with auto scaling resources*
<img width="900" height="625" alt="ec2 module main tf with auto scaling resources" src="https://github.com/user-attachments/assets/c21fa9ae-98e0-4664-8471-cee69b361c88" />

##### *ec2 instances created*
<img width="1702" height="482" alt="ec2 instances created" src="https://github.com/user-attachments/assets/60436d50-6395-4dd0-aa13-9d15878d8a52" />

---

## 🔹 Step 6: Environment Configuration

### Dev (dev.tfvars)

```hcl
instance_type = "t3.micro" 
enable_asg    = false 
```

### Prod (prod.tfvars)
```hcl
instance_type = "t3.large" 
enable_asg    = true 
```

### Result:
- Same codebase → different infrastructure behavior

##### *Prod environment tfvars*
<img width="971" height="579" alt="Prod environment tfvars" src="https://github.com/user-attachments/assets/9fd36b26-35a6-4ce3-a5c2-2d6db9ed6725" />


---

## 🔹 Step 7: Workspaces

```bash
terraform workspace new dev 
terraform workspace new prod
``` 

### Why:
- Isolates environments logically

##### *Creating environments*
<img width="749" height="359" alt="Creating environments" src="https://github.com/user-attachments/assets/24bb29c4-6ad5-46d8-b87d-970956157ce0" />

---

## 🔹 Step 8: Deployment Workflow

```bash
terraform init
terraform workspace select dev
terraform plan -var-file="environments/dev/dev.tfvars"
terraform apply -var-file="environments/dev/dev.tfvars"
``` 

```bash
terraform init
terraform workspace select prod
terraform plan -var-file="environments/prod/prod.tfvars"
terraform apply -var-file="environments/prod/prod.tfvars"
``` 

##### *Terraform planning*
<img width="755" height="904" alt="Terraform planning" src="https://github.com/user-attachments/assets/9ef22d01-a23b-4508-b527-af3bcb377cb3" />

##### *Creating environments*
<img width="751" height="909" alt="Successful production deployment via Terraform apply" src="https://github.com/user-attachments/assets/07448cdf-8bc5-482c-907d-46f14a38de91" />

---

# ✅ Working Application
---

##### *ec2 instances created*
<img width="1702" height="482" alt="ec2 instances created" src="https://github.com/user-attachments/assets/542597c4-42fa-404a-9c80-243f714bb475" />

##### *Dafault vpc created*
<img width="1702" height="482" alt="Dafault vpc created" src="https://github.com/user-attachments/assets/75745e72-de05-483b-813c-b4ba051b106e" />


# ⚠️ Challenges & Solutions

---

## ❌ Challenge 1: Terraform State Lock Errors

### Error:
text Error acquiring the state lock 

### Cause:
- Interrupted Terraform execution

### ✅ Solution:
bash terraform force-unlock <LOCK_ID> 

---


## 📬 Contact  
If you’re a recruiter or hiring manager looking for a Cloud/DevOps Engineer, feel free to connect via email at samuel.tfio@gmail.com

## 🔗 Links

[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/samuel-tettey-fio/)


## Authors

- [@bigsam233](https://www.github.com/bigsam233)
