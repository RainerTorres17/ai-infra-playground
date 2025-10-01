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
variable "node_group_capacity_type"{
    type = string
    default = "ON_DEMAND"

}
variable "node_instance_types"{
    type = list
    default = ["t3a.medium"]
}
variable "node_desired_size"{
    type = number
    default = 1
}
variable "node_min_size"{
    type = number
    default = 1

}
variable "node_max_size"{
    type = number
    default = 3
}
variable "node_volume_size_gb"{
    type = number
    default = 20
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
