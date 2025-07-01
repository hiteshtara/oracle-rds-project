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


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "oracle-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "sg" {
  name   = "oracle-db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "oracle_subnet_group" {
  name       = "oracle-subnet-group"
  subnet_ids = [aws_subnet.public.id]
}

resource "aws_db_instance" "oracle" {
  identifier             = "oracle-db"
  engine                 = "oracle-se2"
  engine_version         = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  instance_class         = "db.t3.medium"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = "admin"
  password               = "ChangeMe123!"
  db_name                = "ORCL"
  port                   = 1521
  publicly_accessible    = true
  db_subnet_group_name   = aws_db_subnet_group.oracle_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg.id]
  skip_final_snapshot    = true
}

resource "aws_s3_bucket" "schema_bucket" {
  bucket = "oracle-sample-schema-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

output "s3_bucket_name" {
  value = aws_s3_bucket.schema_bucket.bucket
}

output "oracle_rds_endpoint" {
  value = aws_db_instance.oracle.endpoint
}
