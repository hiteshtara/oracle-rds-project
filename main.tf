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
output "s3_bucket_name" {
  value = aws_s3_bucket.schema_bucket.bucket
}

output "oracle_rds_endpoint" {
  value = aws_db_instance.oracle.endpoint
}
