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

# VPC
variable "vpc_id" {
    type = string
    default = "vpc-0e1f1f1f1f1f1f1f1"
}

variable "subnet_ids" {
    type = list
    default = ["subnet-0e1f1f1f1f1f1f1f1","subnet-0e1f1f1f1f1f1f1f1","subnet-0e1f1f1f1f1f1f1f1"]
  
}