#S3 Variables
variable "mlflow_bucket_versioning" {
  type = bool
  default = true
}

variable "mlflow_bucket_lifecycle" {
  type = map(number)
  default = {
    to_ia_days = 30
    expire_days = 60
  }
}

#IRSA Variables

variable "oidc_provider_arn" {
  type = string
  default = "XXXXXXXXXXXXXXXXXXXXXXXXXXX"
}
variable "oidc_issuer" {
  type = string
  default = "https://XXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

#RDS Variables
variable "rds_engine" {
  type = string
  default = "mysql"
}

variable "rds_allocated_storage_gb" {
  type = number
  default = 20
}

variable "rds_instance_class" {
  type = string
  default = "db.t2.micro"
}

variable "rds_multi_az" {
  type = bool
  default = false
  }

variable "rds_backup_retention" {
  type = number
  default = 7
}

variable "rds_public_accessible" {
  type = bool
  default = true
}

variable "rds_skip_final_snapshot" {
  type = bool
  default = true
}

variable "rds_deletion_protection" {
  type = bool
  default = false
}

#Network
variable "vpc_id" {
    type = string
    default = "vpc-0f1c2d3e"
}
  
variable "private_subnets" {
    type = list(string)
    default = ["subnet-0f1c2d3e", "subnet-0f1c2d3e"]
}

variable "allowed_source_sg_id" {
  type = string
  default = "sg-0f1c2d3e"
}

#Credentials
variable "username" {
    type = string
    sensitive = true
}

variable "password" {
    type = string
    sensitive = true
}