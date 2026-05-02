variable "vpc_cidr" {}
variable "public_subnets" {
  type = list(string)
}
variable "env_name" {}