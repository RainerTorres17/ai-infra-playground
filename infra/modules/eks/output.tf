output "oidc_provider"{
    value = module.eks.oidc_provider
    description = "The OIDC Provider URL"

}
output "oidc_provider_arn" {
    value = module.eks.oidc_provider_arn
    description =  "The ARN of the OIDC Provider if `enable_irsa = true`"
}
output "node_sg" {
  value       = module.eks.node_security_group_id
  description = "Security Group created for EKS worker nodes"
}