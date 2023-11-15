locals {
  cur_reports_bucket_name = var.bucket_name != null ? var.bucket_name : "aws-cur-reports-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "allow_access_to_curreports" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
    ]

    resources = [
      "arn:aws:s3:::${local.cur_reports_bucket_name}"
    ]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.cur_reports_bucket_name}/*"
    ]
  }
}

module "cur_reports_bucket" {
  source  = "schubergphilis/mcaf-s3/aws"
  version = "0.11.0"

  name        = local.cur_reports_bucket_name
  kms_key_arn = var.kms_key_arn
  policy      = data.aws_iam_policy_document.allow_access_to_curreports.json
  tags        = var.tags

  lifecycle_rule = [
    {
      id      = "retention"
      enabled = true

      abort_incomplete_multipart_upload = {
        days_after_initiation = 14
      }

      expiration = {
        days = 730
      }

      transition = {
        days          = 90
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  ]
}

resource "aws_cur_report_definition" "default" {
  for_each = var.report_definitions
  provider = aws.us-east-1

  report_name                = each.key
  additional_artifacts       = each.value.additional_artifacts
  additional_schema_elements = each.value.additional_schema_elements
  compression                = each.value.compression
  format                     = each.value.format
  refresh_closed_reports     = each.value.refresh_closed_reports
  report_versioning          = each.value.report_versioning
  s3_bucket                  = module.cur_reports_bucket.name
  s3_prefix                  = each.key
  s3_region                  = data.aws_region.current.name
  time_unit                  = each.value.time_unit
}
