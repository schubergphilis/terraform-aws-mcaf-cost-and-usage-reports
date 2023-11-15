variable "bucket_name" {
  description = "optional bucket name for the AWS CUR reports bucket, if not provided a bucket name will be generated"
  type        = string
  default     = null
}

variable "report_definitions" {
  type = map(object({
    additional_artifacts       = optional(list(string), null)
    additional_schema_elements = list(string)
    compression                = string
    format                     = string
    refresh_closed_reports     = optional(bool, true)
    report_versioning          = optional(string)
    time_unit                  = string
    }
  ))
  default = {
    hourly-gzip = {
      additional_schema_elements = ["RESOURCES"]
      compression                = "GZIP"
      format                     = "textORcsv"
      refresh_closed_reports     = true
      report_versioning          = "CREATE_NEW_REPORT"
      time_unit                  = "HOURLY"
    },
    daily-parquet = {
      additional_artifacts       = ["ATHENA"]
      additional_schema_elements = ["RESOURCES"]
      compression                = "Parquet"
      format                     = "Parquet"
      refresh_closed_reports     = true
      report_versioning          = "OVERWRITE_REPORT"
      time_unit                  = "DAILY"
    }
  }
  description = "AWS Cost and Usage reports definitions"
}

variable "kms_key_arn" {
  type        = string
  description = "The KMS key ARN used for the bucket encryption"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags"
}
