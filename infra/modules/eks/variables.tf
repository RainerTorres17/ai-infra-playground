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
            "desired_size" = 1
            "instance_types" = ["t3.small"]
            "capacity_type"  = "SPOT"
            "disk_size"      = 20
        }
    }
}

# VPC
variable "vpc_id" {
    type = string
    default = "vpc-0e1f1f1f1f1f1f1f1"
}

variable "subnet_ids" {
    type = list
    default = ["subnet-0e1f1f1f1f1f1f1f1","subnet-0e1f1f1f1f1f1f1f1","subnet-0e1f1f1f1f1f1f1f1"]
  
}