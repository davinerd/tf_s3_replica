########## ROLES ###########
#
#
resource "aws_iam_role" "replica_role" {
  name               = "${var.main_bucket_name}-replication_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

########## POLICY DOCS ############
#
#
data "aws_iam_policy_document" "s3_access_policy" {
  count = length(var.s3_actions) > 0 ? 1 : 0
  statement {
    actions = var.s3_actions

    effect = "Allow"

    resources = [
      "${local.s3_bucket_arn}/*",
      local.s3_bucket_arn,
      "${aws_s3_bucket.s3_repl_bucket.arn}/*",
      aws_s3_bucket.s3_repl_bucket.arn,
    ]
  }
}

data "aws_iam_policy_document" "replica_access_policy" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    effect = "Allow"

    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    resources = [
      local.s3_bucket_arn,
    ]
  }

  statement {
    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    effect = "Allow"

    resources = [
      "${local.s3_bucket_arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]
    effect = "Allow"

    resources = [
      "${aws_s3_bucket.s3_repl_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_policy" {
  count = length(var.s3_actions) > 0 ? 1 : 0
  name = "${var.main_bucket_name}-policy"
  policy = length(var.s3_actions) > 0 ? data.aws_iam_policy_document.s3_access_policy[0].json : ""
}

resource "aws_iam_policy" "replica_policy" {
  name = "${var.main_bucket_name}-replication_policy"
  policy = data.aws_iam_policy_document.replica_access_policy.json
}

resource "aws_iam_policy_attachment" "replica_attach" {
  name = "${var.main_bucket_name}-repl_policy_attachment"
  roles = [aws_iam_role.replica_role.name]
  policy_arn = aws_iam_policy.replica_policy.arn
}

resource "aws_iam_policy_attachment" "s3_attach" {
  count = length(var.access_roles_name) > 0 ? 1 : 0
  name = "${var.main_bucket_name}-policy_attachment"
  roles = var.access_roles_name
  policy_arn = length(var.s3_actions) > 0 ? aws_iam_policy.s3_policy[0].arn : ""
}

