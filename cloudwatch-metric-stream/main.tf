provider "aws" {
  region = var.AWS_REGION
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
locals {
  account_id            = data.aws_caller_identity.current.account_id
  create_encryption_key = var.enable_server_side_encryption && var.create_encryption_key && var.firehose_encryption_key_arn == ""
  encryption_key_arn = var.firehose_encryption_key_arn != "" ? var.firehose_encryption_key_arn : (
    local.create_encryption_key ? aws_kms_key.splunk_metric_streams_key[0].arn : ""
  )
  use_customer_managed_key = var.enable_server_side_encryption && local.encryption_key_arn != ""
}

# Resources
resource "aws_kms_key" "splunk_metric_streams_key" {
  count = local.create_encryption_key ? 1 : 0

  description         = "Customer-managed key for Splunk metric streams Firehose encryption in ${var.AWS_REGION}"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EnableIAMUserPermissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root",
        },
        Action   = "kms:*",
        Resource = "*",
      },
      {
        Sid    = "AllowFirehoseUseOfTheKey",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com",
        },
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt",
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = local.account_id,
            "kms:ViaService"    = "firehose.${var.AWS_REGION}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowFirehoseToCreateGrants",
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com",
        },
        Action   = "kms:CreateGrant",
        Resource = "*",
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          },
          StringEquals = {
            "kms:CallerAccount" = local.account_id,
            "kms:ViaService"    = "firehose.${var.AWS_REGION}.amazonaws.com"
          }
        }
      },
    ],
  })

  tags = {
    splunk-metric-streams-key = var.AWS_REGION
  }
}

resource "aws_s3_bucket" "splunk_metric_streams_s3" {
  bucket = "splunk-metric-streams-s3-${local.account_id}-${var.AWS_REGION}"
}

resource "aws_cloudwatch_log_group" "splunk_metric_streams_kinesis_firehose_log_group" {
  name              = "/aws/kinesisfirehose/splunk-metric-streams-${var.AWS_REGION}"
  retention_in_days = 14
}


resource "aws_cloudwatch_log_stream" "splunk_metric_streams_kinesis_firehose_http_log_stream" {
  name           = "HttpEndpointDelivery"
  log_group_name = aws_cloudwatch_log_group.splunk_metric_streams_kinesis_firehose_log_group.name
}

resource "aws_iam_role" "splunk_metric_streams_s3_role" {
  name = "splunk-metric-streams-s3-${var.AWS_REGION}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "firehose.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })

  inline_policy {
    name = "s3_firehose"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          "Action" : [
            "logs:PutLogEvents"
          ],
          Resource = "${aws_cloudwatch_log_group.splunk_metric_streams_kinesis_firehose_log_group.arn}:*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ],
          "Resource" : [
            "${aws_s3_bucket.splunk_metric_streams_s3.arn}",
            "${aws_s3_bucket.splunk_metric_streams_s3.arn}/*"
          ],
          "Effect" : "Allow"
        }
      ],
    })
  }


  tags = {
    Name = "splunk-metric-streams-s3",
  }
}

resource "aws_kinesis_firehose_delivery_stream" "splunk_metric_streams_kinesis_firehose" {
  name = "splunk-metric-streams-${var.AWS_REGION}"

  destination = "http_endpoint"

  dynamic "server_side_encryption" {
    for_each = var.enable_server_side_encryption ? [1] : []
    content {
      enabled  = true
      key_type = local.use_customer_managed_key ? "CUSTOMER_MANAGED_CMK" : "AWS_OWNED_CMK"
      key_arn  = local.use_customer_managed_key ? local.encryption_key_arn : null
    }
  }

  http_endpoint_configuration {
    url        = "${var.splunk_ingest_url}/v1/cloudwatch_metric_stream"
    role_arn   = aws_iam_role.splunk_metric_streams_s3_role.arn
    access_key = var.splunk_access_token
    name       = "Splunk"

    buffering_size     = 1
    buffering_interval = 60

    request_configuration {
      content_encoding = "GZIP"
    }

    s3_backup_mode = "FailedDataOnly"

    s3_configuration {
      bucket_arn         = aws_s3_bucket.splunk_metric_streams_s3.arn
      compression_format = "GZIP"
      role_arn           = aws_iam_role.splunk_metric_streams_s3_role.arn

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.splunk_metric_streams_kinesis_firehose_log_group.name
        log_stream_name = aws_cloudwatch_log_stream.splunk_metric_streams_kinesis_firehose_http_log_stream.name
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.splunk_metric_streams_kinesis_firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.splunk_metric_streams_kinesis_firehose_http_log_stream.name
    }
  }

  tags = {
    splunk-metric-streams-firehose = var.AWS_REGION
  }
}

resource "aws_iam_role" "splunk_metric_stream_role" {
  name = "splunk-metric-streams-${var.AWS_REGION}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "streams.metrics.cloudwatch.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })

  path = "/"

  inline_policy {
    name = "firehose_put"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "firehose:PutRecord",
            "firehose:PutRecordBatch",
          ],
          Resource = aws_kinesis_firehose_delivery_stream.splunk_metric_streams_kinesis_firehose.arn,
        },
      ],
    })
  }

  dynamic "inline_policy" {
    for_each = local.use_customer_managed_key ? [1] : []
    content {
      name = "firehose_kms"

      policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
          {
            Effect = "Allow",
            Action = [
              "kms:GenerateDataKey",
              "kms:Decrypt",
            ],
            Resource = local.encryption_key_arn,
          },
        ],
      })
    }
  }

  description = "A role that allows CloudWatch MetricStreams to publish to Kinesis Firehose"

  tags = {
    splunk-metric-streams-role = var.AWS_REGION
  }
}
