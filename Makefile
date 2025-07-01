# Load AWS credentials from .env if available
include .env
export

# Extract Terraform and AWS resource values
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
	@if [ ! -f hr-schema.zip ]; then \
		echo "⬇️  Downloading hr-schema.zip from Dropbox..."; \
		curl -L -o hr-schema.zip "https://www.dropbox.com/scl/fi/n3srsryg6xqytkq1f5dhv/hr-schema.zip?rlkey=8dxbyqg7ylm8ijjovrh4u7dz9&dl=1"; \
	fi
	@echo "📤 Uploading hr-schema.zip to S3 bucket: $(BUCKET)"
	aws s3 cp hr-schema.zip s3://$(BUCKET)/hr-schema.zip --region $(REGION)

load-schema:
	@echo "🚀 Running SSM command to load HR schema into Oracle RDS..."
	aws ssm send-command \
		--document-name "AWS-RunShellScript" \
		--instance-ids "$(LOADER)" \
		--comment "Load Oracle HR schema into RDS" \
		--parameters 'commands=[
		  "yum install -y unzip wget oracle-instantclient-release-el7",
		  "amazon-linux-extras enable epel && yum install -y oracle-instantclient-basic oracle-instantclient-sqlplus",
		  "aws s3 cp s3://$(BUCKET)/hr-schema.zip /tmp/hr.zip",
		  "unzip -o /tmp/hr.zip -d /tmp/hr",
		  "cd /tmp/hr",
		  "sqlplus admin/ChangeMe123!@$(ENDPOINT):1521/ORCL @hr_main.sql"
		]' \
		--region $(REGION)

destroy:
	terraform destroy -auto-approve
