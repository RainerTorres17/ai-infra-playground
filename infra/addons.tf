resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.43.0"

  values = [yamlencode({
    autoDiscovery = { clusterName = module.eks.cluster_name }
    awsRegion     = var.region
    rbac = {
      serviceAccount = {
        create = true
        name   = "cluster-autoscaler"
        annotations = {
          "eks.amazonaws.com/role-arn" = module.eks.autoscaler_role_arn
        }
      }
    }
  })]

  depends_on = [module.eks]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = "3.12.2"

  depends_on = [module.eks]
}

#Currently focusing on local testing only
#Consider enabling in the future to test external access

#resource "helm_release" "aws_load_balancer_controller" {
#  name       = "aws-load-balancer-controller"
#  repository = "https://aws.github.io/eks-charts"
#  chart      = "aws-load-balancer-controller"
#  namespace  = "kube-system"
#  version    = "1.9.2" # pin a tested version
#
#  values = [yamlencode({
#    clusterName = module.eks.cluster_name
#    region      = var.region
#    vpcId       = module.vpc.vpc_id # optional but helpful in some setups
#
#    serviceAccount = {
#      create = true
#      name   = "load-balancer-controller"
#      annotations = {
#        "eks.amazonaws.com/role-arn" = module.eks.aws_load_balancer_controller_role_arn
#      }
#    }
#  })]
#
#  depends_on = [module.eks]
#}