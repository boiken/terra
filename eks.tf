data "aws_partition" "current" {}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = local.cluster_name
  version  = "1.33"
  role_arn = aws_iam_role.k8s_role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids              = [aws_subnet.vpc_frankfurt_subnet1.id, aws_subnet.vpc_frankfurt_subnet2.id, aws_subnet.vpc_frankfurt_subnet3.id]
    security_group_ids      = [aws_security_group.eks_api_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role.k8s_role,
  ]
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name  = aws_eks_cluster.eks_cluster.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = "v1.3.0-eksbuild.1"
}

resource "aws_eks_node_group" "system_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "system-nodes"
  node_role_arn   = module.karpenter_node_role.iam_role_arn
  subnet_ids      = [aws_subnet.vpc_frankfurt_subnet1.id, aws_subnet.vpc_frankfurt_subnet2.id, aws_subnet.vpc_frankfurt_subnet3.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    module.karpenter_node_role
  ]
}
