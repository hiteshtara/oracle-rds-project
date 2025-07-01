include .env
export

BUCKET := $(shell terraform output -raw s3_bucket_name 2>/dev/null)
ENDPOINT := $(shell terraform output -raw oracle_rds_endpoint 2>/dev/null)
LOADER := $(shell aws ec2 describe-instances --filters "Name=tag:Name,Values=oracle-loader" --query "Reservations[].Instances[].InstanceId" --output text)
REGION := us-east-1

.PHONY: all init plan apply upload-schema load-schema destroy

all: init plan apply upload-schema load-schema

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply -auto-approve

upload-schema:
	git clone https://github.com/oracle/db-sample-schemas.git || true
	cd db-sample-schemas/hr && zip -r ../../hr-schema.zip *
	mv hr-schema.zip ./ || true
	aws s3 cp hr-schema.zip s3://$(BUCKET)/hr-schema.zip --region $(REGION)

load-schema:
	aws ssm send-command \
		--document-name "AWS-RunShellScript" \
		--instance-ids "$(LOADER)" \
		--comment "Load Oracle HR schema into RDS" \
		--parameters 'commands=[
		  "yum install -y unzip wget oracle-instantclient-release-el7",
		  "amazon-linux-extras enable epel && yum install -y oracle-instantclient-basic oracle-instantclient-sqlplus",
		  "aws s3 cp s3://$(BUCKET)/hr-schema.zip /tmp/hr.zip",
		  "unzip -o /tmp/hr.zip -d /tmp/hr",
		  "cd /tmp/hr/hr",
		  "sqlplus admin/ChangeMe123!@$(ENDPOINT):1521/ORCL @hr_main.sql"
		]' \
		--region $(REGION)

destroy:
	terraform destroy -auto-approve
