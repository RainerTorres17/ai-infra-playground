variable "region"{
    type = string
    default = "us-east-1"
}

# VPC
variable "vpc_cidr"{
    type = string
    default = "10.0.0.0/16"
}

variable "public_subnets" {
    type = list
    default = ["10.0.1.0/24","10.0.2.0/24"]
}
  
variable "private_subnets" {
    type = list
    default = ["10.0.3.0/24","10.0.4.0/24"]
}
  
variable "enable_nat_gateway" {
    type = bool
    default = true
}

#EKS
variable "cluster_name" {
    type = string
    default = "my-cluster"
}
  
variable "cluster_version" {
    type = string
    default = "1.22"
}

variable "endpoint_public_access" {
    type = bool
    default = false
}
  
variable "cluster_log_types" {
    type = list
    default = ["api","audit","authenticator","controllerManager","scheduler"]
  
}

# Node
variable "eks_managed_node_groups" {
    type = map (any)
    default = {
        "default" = {
            "min_size" = 0
            "max_size" = 1
            "desired_size" = 0
            "instance_types" = ["t3.small"]
            "capacity_type"  = "SPOT"
            "disk_size"      = 20
        }
    }
}

# ECR
variable "ecr_repo_name"{
    type = string
    default = "my-ecr"
}

variable "ecr_scan_on_push" {
    type = bool
    default = true
}

# MLflow

variable "mlflow_bucket_versioning"{
    type = bool
    default = true
}

variable "mlflow_bucket_lifecycle"{
    type = map(number)
    default = {
        to_ia_days = 30
        expire_days = 180
    }
}

# RDS Variables
variable "rds_engine"{
    type = string
    default = "postgress"
}

variable "rds_instance_class"{
    type = string
    default = "db.t3.micro"
}

variable "rds_allocated_storage_gb"{
    type = number
    default = 20
}

variable "rds_multi_az"{
    type = bool
    default = false
}

variable "rds_backup_retention"{
    type = number
    default = 7
}

variable "rds_public_accessible"{
    type = bool
    default = false
}

variable "rds_deletion_protection"{
    type = bool
    default = false
}

variable "rds_skip_final_snapshot"{
    type = bool
    default = true
}

#Credentials

variable "rds_username"{
    type = string
    sensitive = true
}

variable "rds_password"{
    type = string
    sensitive = true
}

#Github repo
variable "github_repo"{
    type = string
    default = "mlflow-mlops"
}