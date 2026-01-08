resource "aws_security_group" "eks_api_sg" {
  name        = "eks_api_sg"
  description = "Security group for EKS to make it reachable from inside the VPC"
  vpc_id      = aws_vpc.vpc_frankfurt.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.cidr_frankfurt]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                     = "eks_api_sg_test"
    "karpenter.sh/discovery" = local.cluster_name
  }
}
