terraform {
  backend "s3" {
    bucket         = "my-terraform-state-buck-sam"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}