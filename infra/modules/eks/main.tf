module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.3.1"

  name    = var.cluster_name
  kubernetes_version = var.cluster_version
  vpc_id          = var.vpc_id
  subnet_ids      = var.subnet_ids
  endpoint_public_access = var.endpoint_public_access

  enabled_log_types = var.cluster_log_types

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    
    default = {
    min_size       = var.node_min_size
    max_size       = var.node_max_size
    desired_size   = var.node_desired_size
    instance_types = var.node_instance_types
    capacity_type  = var.node_group_capacity_type
    disk_size      = var.node_volume_size_gb
    }
    
  }

}

resource "aws_cloudwatch_log_group" "eks" {
  name = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
  skip_destroy = false
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

data "aws_iam_policy_document" "assume" {
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

resource "aws_iam_policy" "autoscaler" {
  name = "autoscaler"
  policy = data.aws_iam_policy_document.autoscaler.json
}

resource "aws_iam_role" "helm_irsa" {
  name = "autoscaler"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role = aws_iam_role.helm_irsa.name
  policy_arn = aws_iam_policy.autoscaler.arn
}
