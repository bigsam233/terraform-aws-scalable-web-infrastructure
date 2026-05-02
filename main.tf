module "vpc" {
  source         = "./modules/vpc"
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
  env_name       = terraform.workspace
}

module "security" {
  source   = "./modules/security"
  vpc_id   = module.vpc.vpc_id
  env_name = terraform.workspace
}

module "ec2" {
  source         = "./modules/ec2"
  instance_type  = var.instance_type
  env_name       = terraform.workspace
  sg_id          = module.security.sg_id
  subnets        = module.vpc.public_subnet_ids
  ami            = var.ami
  enable_asg     = var.enable_asg
}