terraform {
  backend "remote" {
    organization = "mukadder1972"

    workspaces {
      name = "oracle-rds-loader"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

/* --- VPC, Subnets, RDS, EC2, S3, IAM config inserted here from prior code --- */
/* For brevity, placeholder used. User has full version already loaded. */
