resource "aws_s3_bucket" "this" {
    bucket = "ai-playground-mlflow-artifacts"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.mlflow_bucket_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "lifecycle"
    status = "Enabled"

    transition {
      days          = var.mlflow_bucket_lifecycle["to_ia_days"]
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.mlflow_bucket_lifecycle["expire_days"]
    }
  }
}

resource "aws_s3_bucket_public_access_block" "name" {
    bucket = aws_s3_bucket.this.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_iam_policy" "artifact_policy" {
    name = "mlflow-s3-policy"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:ListBucketVersions"
            ],
            "Resource": [
                "${aws_s3_bucket.this.arn}"
            ]
        }
        ,
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetObjectTagging",
                "s3:PutObject",
                "s3:PutObjectTagging",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion"
            ],
            "Resource": [
                "${aws_s3_bucket.this.arn}/*"
            ]
        }
    ]
}
EOF
  
}

# RDS
resource "aws_security_group" "rds" {
  name        = "MLFlowRDS"
  description = "Security group for MLFlow RDS"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "rds_ingress" {
  for_each = toset(var.allowed_source_sg_ids)

  description              = "Allow Postgres traffic from EKS node SGs"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = each.value
}

resource "aws_db_subnet_group" "this" {
  name       = "mlflow-rds"
  subnet_ids = var.public_subnets
}

resource "aws_db_instance" "this" {
  db_name                = "mlflow"
  engine_version         = "16.3"
  instance_class         = var.rds_instance_class
  allocated_storage      = var.rds_allocated_storage_gb
  engine                 = var.rds_engine
  username               = var.username
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.rds_public_accessible
  skip_final_snapshot    = var.rds_skip_final_snapshot
  storage_type = "gp3"
}
