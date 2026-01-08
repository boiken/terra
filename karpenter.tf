resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.0.0" # Check for the latest version

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.karpenter_irsa.iam_role_arn
    },
    {
      name  = "settings.clusterName"
      value = local.cluster_name
    },
    {
      name  = "settings.interruptionQueue"
      value = local.cluster_name
    }
  ]

  # Wait for the cluster to be ready
  depends_on = [module.karpenter_irsa]
}

resource "aws_sqs_queue" "karpenter_interruption" {
  name                      = local.cluster_name
  message_retention_seconds = 300
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption.id
  policy    = data.aws_iam_policy_document.karpenter_interruption_queue.json
}

data "aws_iam_policy_document" "karpenter_interruption_queue" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_interruption.arn]
  }
}

resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  for_each = toset([
    "aws.ec2",
    "aws.health"
  ])

  name        = "${local.cluster_name}-${each.value}"
  description = "Karpenter interruption for ${each.value}"

  event_pattern = jsonencode({
    source = ["${each.value}"]
    detail-type = [
      "EC2 Spot Instance Interruption Warning",
      "EC2 Instance Rebalance Recommendation",
      "EC2 Instance State-change Notification",
      "AWS Health Event"
    ]
  })
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  for_each = aws_cloudwatch_event_rule.karpenter_interruption

  rule      = each.value.name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption.arn
}
