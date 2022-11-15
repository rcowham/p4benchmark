
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "instance" {
  name               = "p4-benchmark-${var.environment}"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "instance" {

  name = "p4-benchmark-${var.environment}"
  path = "/"
  role = aws_iam_role.instance.name
}

resource "aws_iam_role_policy" "list_s3_buckets" {
  count  = var.s3_checkpoint_bucket != "" ? 1 : 0
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.list_s3_buckets.0.json
}

resource "aws_iam_role_policy" "my_bucket_actions" {
  count  = var.s3_checkpoint_bucket != "" ? 1 : 0
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.my_bucket_actions.0.json
}


data "aws_iam_policy_document" "list_s3_buckets" {
  count = var.s3_checkpoint_bucket != "" ? 1 : 0

  statement {
    sid = "1"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListAllMyBuckets"
    ]

    resources = [
      "arn:aws:s3:::*"
    ]
  }
}

data "aws_iam_policy_document" "my_bucket_actions" {
  count = var.s3_checkpoint_bucket != "" ? 1 : 0

  statement {
    sid = "1"

    actions = [
      "s3:ListBucket",
      "s3:ListObject",
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::${var.s3_checkpoint_bucket}",
      "arn:aws:s3:::${var.s3_checkpoint_bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
