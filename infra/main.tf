provider "aws" {
  region =  "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.4.0"

  name = "ai-playground"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.3.1"

  name    = var.cluster_name
  kubernetes_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  endpoint_public_access = var.endpoint_public_access

  enabled_log_types = var.cluster_log_types

  eks_managed_node_groups = {
    
    default = {
    min_size       = var.node_min_size
    max_size       = var.node_max_size
    desired_size   = var.node_desired_size
    instance_types = var.node_instance_types
    capacity_type  = var.node_group_capacity_type  # "SPOT" or "ON_DEMAND"
    disk_size      = var.node_volume_size_gb
    # optional: labels, taints, ami_type, iam_role_additional_policies, etc.
    }
    
  }

}

module "ecr" {
    source = "./modules/ecr"
    name = var.ecr_repo_name
    scan_on_push = var.ecr_scan_on_push
  }

module "mlflow"{
  source = "./modules/mlflow"
  mlflow_bucket_versioning = var.mlflow_bucket_versioning
  mlflow_bucket_lifecycle = var.mlflow_bucket_lifecycle
  rds_engine = var.rds_engine
  rds_allocated_storage_gb = var.rds_allocated_storage_gb
  rds_instance_class = var.rds_instance_class
  rds_multi_az = var.rds_multi_az
  rds_backup_retention = var.rds_backup_retention
  rds_public_accessible = var.rds_public_accessible
  rds_skip_final_snapshot = var.rds_skip_final_snapshot
  rds_deletion_protection = var.rds_deletion_protection
  vpc_id = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  allowed_source_sg_ids = [module.eks.node_security_group_id]
  username = var.rds_username
  password = var.rds_password
}