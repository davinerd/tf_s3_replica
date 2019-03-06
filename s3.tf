# this is the main (source) bucket
resource "aws_s3_bucket" "s3_bucket" {
  count  = "${var.logs_enabled ? 1 : 0}"
  bucket = "${var.main_bucket_name}"
  acl    = "private"

  force_destroy = "${var.force_destroy}"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_bucket.id}"
  }

  lifecycle_rule {
    id      = "rotate"
    enabled = true

    transition {
      days          = "${var.transition_days}"
      storage_class = "${var.transition_storage_class}"
    }
  }

  replication_configuration {
    role = "${aws_iam_role.replica_role.arn}"

    rules {
      id     = "repl_rule"
      status = "Enabled"

      destination {
        bucket        = "${aws_s3_bucket.s3_repl_bucket.arn}"
        storage_class = "${var.replica_storage_class}"
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = "${merge(map("Name", var.main_bucket_name), var.extra_tags)}"
}

resource "aws_s3_bucket" "s3_bucket_no_logs" {
  count  = "${var.logs_enabled ? 0 : 1}"
  bucket = "${var.main_bucket_name}"
  acl    = "private"

  force_destroy = "${var.force_destroy}"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "rotate"
    enabled = true

    transition {
      days          = "${var.transition_days}"
      storage_class = "${var.transition_storage_class}"
    }
  }

  replication_configuration {
    role = "${aws_iam_role.replica_role.arn}"

    rules {
      id     = "repl_rule"
      status = "Enabled"

      destination {
        bucket        = "${aws_s3_bucket.s3_repl_bucket.arn}"
        storage_class = "${var.replica_storage_class}"
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = "${merge(map("Name", var.main_bucket_name), var.extra_tags)}"
}

resource "aws_s3_bucket" "s3_repl_bucket" {
  provider = "aws.repl"
  bucket   = "${var.replication_bucket_name}"

  force_destroy = "${var.force_destroy}"

  lifecycle_rule {
    id      = "rotate"
    enabled = true

    transition {
      days          = "${var.transition_days}"
      storage_class = "${var.transition_storage_class}"
    }
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = "${merge(map("Name", "${var.main_bucket_name}-repl"), var.extra_tags)}"
}

# logging of the source bucket
resource "aws_s3_bucket" "log_bucket" {
  count  = "${var.logs_enabled ? 1 : 0}"
  bucket = "${var.main_bucket_name}-logs"
  acl    = "log-delivery-write"

  force_destroy = "${var.force_destroy}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = "${merge(map("Name", "${var.main_bucket_name}-logs"), var.extra_tags)}"
}

resource "aws_s3_bucket_public_access_block" "s3_public_access_block" {
  bucket = "${local.s3_bucket_id}"

  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

resource "aws_s3_bucket_public_access_block" "s3_replica_public_access_block" {
  bucket = "${aws_s3_bucket.s3_repl_bucket.id}"

  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}