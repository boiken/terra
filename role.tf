resource "aws_iam_policy" "describe_ec2_policy" {
  name        = "KarpenterDescribeEC2Policy"
  description = "Allows describing EC2 instances"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    }
  ]
}
EOF
}

# ###### K8s Service Role #########

resource "aws_iam_role" "k8s_role" {
  name = "k8s_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "k8s_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.k8s_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "describe_ec2_attachment_k8s" {
  role       = aws_iam_role.k8s_role.name
  policy_arn = aws_iam_policy.describe_ec2_policy.arn
}


# --- 1. Karpenter Controller Role (IRSA) ---
module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                          = "karpenter-controller-eks"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name       = aws_eks_cluster.eks_cluster.name
  karpenter_controller_node_iam_role_arns = [module.karpenter_node_role.iam_role_arn]

  karpenter_sqs_queue_arn = aws_sqs_queue.karpenter_interruption.arn

  oidc_providers = {
    ex = {
      provider_arn               = aws_iam_openid_connect_provider.oidc.arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

# --- 2. Karpenter Node Role ---
module "karpenter_node_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.0"

  role_name         = "karpenter-node-eks"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # Recommended for debugging
  ]

  trusted_role_services = ["ec2.amazonaws.com"]
}

# --- 3. Karpenter Instance Profile ---
# Required for the EC2 instances to launch
resource "aws_iam_instance_profile" "karpenter_node" {
  name = "karpenter-node-eks"
  role = module.karpenter_node_role.iam_role_name
}
