include .env
export

BUCKET := $(shell terraform output -raw s3_bucket_name 2>/dev/null)
ENDPOINT := $(shell terraform output -raw oracle_rds_endpoint 2>/dev/null)
REGION := us-east-1

.PHONY: all init plan apply upload-schema load-schema destroy

all: init plan apply upload-schema load-schema

init:
	terraform init -reconfigure

plan:
	terraform plan

apply:
	terraform apply -auto-approve

upload-schema:
	@if [ -z "$(BUCKET)" ]; then \
		echo "❌ ERROR: S3 bucket name not found. Did you run 'terraform apply'?"; \
		exit 1; \
	fi
	@if [ ! -f hr-schema.zip ]; then \
		echo "⬇️  Downloading hr-schema.zip from Dropbox..."; \
		curl -L -o hr-schema.zip "https://www.dropbox.com/scl/fi/n3srsryg6xqytkq1f5dhv/hr-schema.zip?rlkey=8dxbyqg7ylm8ijjovrh4u7dz9&dl=1"; \
	fi
	aws s3 cp hr-schema.zip s3://$(BUCKET)/hr-schema.zip --region $(REGION)

load-schema:
	@echo "ℹ️  You must manually trigger the schema load via SSM or EC2 access (not auto-provisioned here)"

destroy:
	terraform destroy -auto-approve
