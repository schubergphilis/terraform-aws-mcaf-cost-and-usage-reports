variable "bucket_name" {
  type        = string
  default     = null
  description = "optional bucket name for the AWS CUR reports bucket, if not provided a bucket name will be generated"
}

variable "kms_key_arn" {
  type        = string
  description = "The KMS key ARN used for the bucket encryption"
}

variable "legacy_reporting" {
  type        = bool
  default     = false
  description = "Enable legacy reporting"
}

variable "report_definitions" {
  type = map(object({
    compression                           = string
    format                                = string
    include_capacity_reservation_data     = optional(bool, false)
    include_manual_discount_compatibility = optional(bool, false)
    include_resources                     = optional(bool, false)
    include_split_cost_allocation_data    = optional(bool, false)
    overwrite                             = optional(string, "CREATE_NEW_REPORT")
    time_unit                             = string
    }
  ))
  default = {
    hourly-gzip = {
      compression       = "GZIP"
      format            = "TEXT_OR_CSV"
      overwrite         = "CREATE_NEW_REPORT"
      time_unit         = "HOURLY"
      include_resources = true
    },
    daily-parquet = {
      compression       = "PARQUET"
      format            = "PARQUET"
      overwrite         = "OVERWRITE_REPORT"
      time_unit         = "DAILY"
      include_resources = true
    }
  }
  description = "AWS Cost and Usage reports definitions using BCM Data Exports. Key is used as export name and as prefix in the s3 bucket to store the export files."

  validation {
    condition = alltrue([
      for k, v in var.report_definitions : contains(["GZIP", "PARQUET"], v.compression)
    ])
    error_message = "Compression must be one of: GZIP, or PARQUET."
  }

  validation {
    condition = alltrue([
      for k, v in var.report_definitions : contains(["TEXT_OR_CSV", "PARQUET"], v.format)
    ])
    error_message = "Format must be one of: TEXT_OR_CSV, or PARQUET."
  }

  validation {
    condition = alltrue([
      for k, v in var.report_definitions : contains(["CREATE_NEW_REPORT", "OVERWRITE_REPORT"], v.overwrite)
    ])
    error_message = "Overwrite must be either CREATE_NEW_REPORT or OVERWRITE_REPORT."
  }

  validation {
    condition = alltrue([
      for k, v in var.report_definitions : contains(["HOURLY", "DAILY", "MONTHLY"], v.time_unit)
    ])
    error_message = "Time unit must be one of: HOURLY, DAILY, or MONTHLY."
  }

  validation {
    condition = alltrue([
      for k, v in var.report_definitions :
      v.compression == "PARQUET" ? (v.format == "PARQUET") : true
    ])
    error_message = "When compression is PARQUET, format must also be PARQUET."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags"
}
