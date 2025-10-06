provider "aws" {
  region =  "us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.4.0"

  map_public_ip_on_launch = true

  name = "ai-playground"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = var.enable_nat_gateway

  public_subnet_tags = {
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${var.cluster_name}"      = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/${var.cluster_name}"      = "shared"
  }

}

module "eks" {
  source  = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnets
  endpoint_public_access = var.endpoint_public_access

  cluster_log_types = var.cluster_log_types

    
  eks_managed_node_groups = var.eks_managed_node_groups

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
  oidc_provider_arn =  module.eks.oidc_provider_arn
  oidc_issuer = module.eks.oidc_provider
  rds_engine = var.rds_engine
  rds_allocated_storage_gb = var.rds_allocated_storage_gb
  rds_instance_class = var.rds_instance_class
  rds_multi_az = var.rds_multi_az
  rds_backup_retention = var.rds_backup_retention
  rds_public_accessible = var.rds_public_accessible
  rds_skip_final_snapshot = var.rds_skip_final_snapshot
  rds_deletion_protection = var.rds_deletion_protection
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  allowed_source_sg_id = module.eks.node_sg
  username = var.rds_username
  password = var.rds_password
}