locals {
    s3_bucket_id = "${var.logs_enabled ? element(concat(aws_s3_bucket.s3_bucket.*.id, list("")), 0) : element(concat(aws_s3_bucket.s3_bucket_no_logs.*.id, list("")), 0)}"

    s3_bucket_arn = "${var.logs_enabled ? element(concat(aws_s3_bucket.s3_bucket.*.arn, list("")), 0) : element(concat(aws_s3_bucket.s3_bucket_no_logs.*.arn, list("")), 0)}"

}