#!/bin/bash

BUCKET_NAME=$(terraform output -raw s3_bucket_name)
ORACLE_ENDPOINT=$(terraform output -raw oracle_rds_endpoint)
LOADER_INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=oracle-loader" --query "Reservations[].Instances[].InstanceId" --output text)

aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --instance-ids "$LOADER_INSTANCE_ID" \
  --comment "Load Oracle HR schema into RDS" \
  --parameters 'commands=[
    "yum install -y unzip wget oracle-instantclient-release-el7",
    "amazon-linux-extras enable epel && yum install -y oracle-instantclient-basic oracle-instantclient-sqlplus",
    "aws s3 cp s3://'"$BUCKET_NAME"'/hr-schema.zip /tmp/hr.zip",
    "unzip -o /tmp/hr.zip -d /tmp/hr",
    "cd /tmp/hr/hr",
    "sqlplus admin/ChangeMe123!@'"$ORACLE_ENDPOINT"':1521/ORCL @hr_main.sql"
  ]' \
  --region us-east-1
