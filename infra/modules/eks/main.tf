module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.3.1"

  name    = var.cluster_name
  kubernetes_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  endpoint_public_access = var.endpoint_public_access
  create_cloudwatch_log_group = true
  cloudwatch_log_group_retention_in_days = 14
  enabled_log_types = var.cluster_log_types

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = var.eks_managed_node_groups

}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {

    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

}

# IAM for EKS

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "assume_deploy"{
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = ["sts.amazonaws.com"]
    }
    condition {
      test = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [var.github_repo]
    }
  }
}


data "aws_iam_policy_document" "github_eks_deploy" {
  statement {
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
      "eks:AccessKubernetesApi"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "autoscaler" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_auto" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values = ["sts.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

data "aws_iam_policy_document" "assume_load" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }
    condition {
      test = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values = ["sts.amazonaws.com"]
    }
    condition {
      test = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values = ["system:serviceaccount:kube-system:load-balancer-controller"]
    }
  }
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "aws_load_balancer_controller"
  policy = file("modules/eks/controller_policy.json")
}

resource "aws_iam_policy" "autoscaler" {
  name = "autoscaler"
  policy = data.aws_iam_policy_document.autoscaler.json
}

resource "aws_iam_policy" "github_eks_deploy"{
  name = "github_eks_deploy"
  policy = data.aws_iam_policy_document.github_eks_deploy.json

}

resource "aws_iam_role" "autoscaler" {
  name = "autoscaler"
  assume_role_policy = data.aws_iam_policy_document.assume_auto.json
}

resource "aws_iam_role" "aws_load_balancer_controller"{
  name = "aws_load_balancer_controller"
  assume_role_policy = data.aws_iam_policy_document.assume_load.json
}

resource "aws_iam_role" "github_eks_deploy" {
  name = "github_eks_deploy"
  assume_role_policy = data.aws_iam_policy_document.assume_deploy.json
}

resource "aws_iam_role_policy_attachment" "autoscaler" {
  role = aws_iam_role.autoscaler.name
  policy_arn = aws_iam_policy.autoscaler.arn
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "aws_iam_role_policy_attachment" "github_eks_deploy" {
  role = aws_iam_role.github_eks_deploy.name
  policy_arn = aws_iam_policy.github_eks_deploy.arn
}

# Map GitHub OIDC deployment role into EKS aws-auth ConfigMap
resource "kubernetes_config_map_v1_data" "aws_auth_github_deploy" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force = true
  data = {
    mapRoles = yamlencode([
      {
        rolearn  = "arn:aws:iam::765568065512:role/github_eks_deploy"
        username = "github-deployer"
        groups   = ["system:masters"]
      }
    ])
  }
  depends_on = [module.eks]
}

