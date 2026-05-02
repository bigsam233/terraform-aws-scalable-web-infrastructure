vpc_cidr       = "10.1.0.0/16"
public_subnets = ["10.1.1.0/24", "10.1.2.0/24"]

instance_type = "t3.large"
enable_asg    = true

ami = "ami-098e39bafa7e7303d"