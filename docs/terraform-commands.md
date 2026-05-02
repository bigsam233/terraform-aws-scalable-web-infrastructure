# Terraform Deployment & Management Scripts

This file contains all the essential commands used to deploy, manage, and destroy the multi-environment Terraform infrastructure.

---

## Initialize Terraform

bash terraform init 

---

## Create Workspaces

bash terraform workspace new dev terraform workspace new prod 

---

## Switch Workspaces

bash terraform workspace select dev terraform workspace select prod 

---

## Validate Configuration

bash terraform validate 

---

## Plan Infrastructure

### Dev
bash terraform plan -var-file="environments/dev/dev.tfvars" 

### Prod
bash terraform plan -var-file="environments/prod/prod.tfvars" 

---

## Apply Infrastructure

### Dev
bash terraform apply -var-file="environments/dev/dev.tfvars" 

### Prod
bash terraform apply -var-file="environments/prod/prod.tfvars" 

---

## Force Recreate Resources

bash terraform apply -replace="module.ec2.aws_autoscaling_group.web[0]" \   -var-file="environments/prod/prod.tfvars" 

---

## Fix State Lock Issues

bash terraform force-unlock <LOCK_ID> 

---

## Reconfigure Backend

bash terraform init -reconfigure \   -backend-config="key=dev/terraform.tfstate" 

---

## Destroy Infrastructure

### Dev
bash terraform workspace select dev terraform destroy -var-file="environments/dev/dev.tfvars" 

### Prod
bash terraform workspace select prod terraform destroy -var-file="environments/prod/prod.tfvars" 

---

## Check Workspaces

bash terraform workspace list 

---

## Notes

- Always run commands from the root directory  
- Always select the correct workspace before applying  
- Always use -var-file for environment configs  
- Never commit .tfstate files  

---

## 👤 Author
Samuel Tettey-Fio