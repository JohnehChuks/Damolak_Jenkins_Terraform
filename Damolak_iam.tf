# =============================================================
# Damolak_iam.tf — IAM Role, Policy & Instance Profile
# Project : Damolak DevOps Challenge
#
# One shared role attached to both EC2 instances.
# Grants: ECR push/pull, S3 read (state), CloudWatch Logs, SSM
# =============================================================

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "damolak_ec2_role" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = var.iam_role_name
  }
}

data "aws_iam_policy_document" "damolak_ec2_policy_doc" {
  statement {
    sid    = "ECRAccess"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3StateReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-terraform-state",
      "arn:aws:s3:::${var.project_name}-terraform-state/*",
    ]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "damolak_ec2_policy" {
  name   = "${var.project_name}-ec2-policy"
  role   = aws_iam_role.damolak_ec2_role.id
  policy = data.aws_iam_policy_document.damolak_ec2_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.damolak_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "damolak_ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.damolak_ec2_role.name

  tags = {
    Name = "${var.project_name}-ec2-profile"
  }
}