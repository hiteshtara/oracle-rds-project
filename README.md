# Oracle RDS Terraform Deployment with HR Schema

## Steps

1. Configure `.env` with your AWS credentials
2. Run `make all` to provision everything
3. Run `make load-schema` or `./ssm-run.sh` to load the HR sample schema
4. Run `make destroy` to tear down

> Connected to Terraform Cloud: `oracle-rds-loader` in org `your-org-name`
