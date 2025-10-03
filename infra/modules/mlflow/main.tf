resource "random_id" "suffix" {
  byte_length = 4
}
resource "aws_s3_bucket" "this" {
    bucket = "ai-playground-mlflow-${random_id.suffix.hex}"
    force_destroy = true
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

    filter {}

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


resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM

data "aws_iam_policy_document" "artifact_policy"{
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion"
     ]
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
  statement {
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]
    resources = [
      aws_s3_bucket.this.arn
     ]
  }
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test = "StringEquals"
      variable = "${var.oidc_issuer}:aud"
      values = ["sts.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "${var.oidc_issuer}:sub"
      values = ["system:serviceaccount:mlops:mlflow-sa"]
    }
  }
}

resource "aws_iam_policy" "artifact_policy" {
    name = "mlflow-s3-policy"
    policy = data.aws_iam_policy_document.artifact_policy.json
}

resource "aws_iam_role" "mlflow_irsa" {
  name = "mlflow-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role = aws_iam_role.mlflow_irsa.name
  policy_arn = aws_iam_policy.artifact_policy.arn
}



# RDS
resource "aws_security_group" "rds" {
  name        = "mlflow-rds"
  description = "Security group for MLFlow RDS"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "rds_ingress" {

  description              = "Allow Postgres traffic from EKS node SGs"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = var.allowed_source_sg_id #single security group for now, will adjust for scaling later
}

resource "aws_db_subnet_group" "this" {
  name       = "mlflow-rds"
  subnet_ids = var.private_subnets
}

resource "aws_db_instance" "this" {
  db_name                = "mlflow"
  engine_version         = "16.3"
  instance_class         = var.rds_instance_class
  allocated_storage      = var.rds_allocated_storage_gb
  backup_retention_period = 0
  engine                 = var.rds_engine
  username               = var.username
  password               = var.password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.rds_public_accessible
  skip_final_snapshot    = var.rds_skip_final_snapshot
  storage_type = "gp3"
}
