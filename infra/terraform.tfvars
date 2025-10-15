# Networking
region                = "us-east-1"
vpc_cidr              = "10.0.0.0/16"
public_subnets        = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets       = ["10.0.3.0/24","10.0.4.0/24"]
enable_nat_gateway    = false

# EKS
cluster_name          = "ai-playground-eks"
cluster_version       = "1.30"
endpoint_public_access = true
cluster_log_types     = []

# Node group (Managed)
eks_managed_node_groups = {
      "default" = {
          "min_size" = 0
          "max_size" = 2
          "desired_size" = 1
          "instance_types" = ["t3.small"]
          "capacity_type"  = "SPOT"
          "disk_size"      = 20
        }
}

# ECR
ecr_repo_name            = "ai-playground-app"
ecr_scan_on_push         = false

# S3 for MLflow artifacts
mlflow_bucket_lifecycle = {
  to_ia_days  = 30,
  expire_days = 180
}
mlflow_bucket_versioning = false

# RDS (PostgreSQL)
rds_engine               = "postgres"
rds_instance_class       = "db.t3.micro"       
rds_allocated_storage_gb = 20
rds_multi_az             = false
rds_backup_retention     = 1
rds_public_accessible    = false
rds_deletion_protection  = false
rds_skip_final_snapshot  = true
rds_username = "mlflow"
rds_password = "S3curePassw0rd!"

# GitHub
github_repo = "repo:RainerTorres17/mlflow-serving-stack:*"