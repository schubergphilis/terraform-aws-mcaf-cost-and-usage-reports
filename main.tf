locals {
  cur_reports_bucket_name = var.bucket_name != null ? var.bucket_name : "aws-cur-reports-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "allow_access_to_curreports" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
    ]

    resources = [
      "arn:aws:s3:::${local.cur_reports_bucket_name}"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bcm-data-exports:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:export/*"]
    }
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["bcm-data-exports.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.cur_reports_bucket_name}/*"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:bcm-data-exports:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:export/*"]
    }
  }
}

module "cur_reports_bucket" {
  source  = "schubergphilis/mcaf-s3/aws"
  version = "~> 2.0.0"

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

      transition = [
        {
          days          = 90
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
    }
  ]
}

resource "aws_bcmdataexports_export" "default" {
  for_each = var.report_definitions

  export {
    name = each.key

    data_query {
      query_statement = "SELECT * FROM COST_AND_USAGE_REPORT"

      table_configurations = {
        COST_AND_USAGE_REPORT = {
          INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY = each.value.include_manual_discount_compatibility ? "TRUE" : "FALSE"
          INCLUDE_CAPACITY_RESERVATION_DATA     = each.value.include_capacity_reservation_data ? "TRUE" : "FALSE"
          INCLUDE_RESOURCES                     = each.value.include_resources ? "TRUE" : "FALSE"
          INCLUDE_SPLIT_COST_ALLOCATION_DATA    = each.value.include_split_cost_allocation_data ? "TRUE" : "FALSE"
          TIME_GRANULARITY                      = each.value.time_unit
        }
      }
    }

    destination_configurations {
      s3_destination {
        s3_bucket = module.cur_reports_bucket.name
        s3_prefix = each.key
        s3_region = data.aws_region.current.name

        s3_output_configurations {
          overwrite   = each.value.overwrite
          format      = each.value.format
          compression = each.value.compression
          output_type = "CUSTOM"
        }
      }
    }

    refresh_cadence {
      frequency = "SYNCHRONOUS"
    }
  }

  tags = var.tags
}
