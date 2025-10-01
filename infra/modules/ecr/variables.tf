variable "name" {
    type = string
    description = "ECR name"
}

variable "scan_on_push"{
    type = bool
    description = "Scan on push"
    default = true
}