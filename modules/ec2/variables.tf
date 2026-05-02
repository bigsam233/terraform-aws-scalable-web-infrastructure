variable "instance_type" {}
variable "env_name" {}
variable "sg_id" {}
variable "subnets" {
  type = list(string)
}
variable "ami" {}
variable "enable_asg" {
  type = bool
}