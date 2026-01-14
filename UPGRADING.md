# Upgrading Notes

This document captures required refactoring on your part when upgrading to a module version that contains breaking changes.

## Upgrading to v1.0.0

### Key Changes

- Added support for `aws_bcmdataexports_export`, which replaces `aws_cur_report_definition` by default.
  - If you still need to use `aws_cur_report_definition`, set `legacy_reporting = true`.
  - **If you use the default reports, this is the only required change.**

- If you use these reports for **Datadog**, you must set `legacy_reporting = true`. Datadog does not yet support BCM Data Exports.

- `aws_bcmdataexports_export` is mostly backward compatible with `aws_cur_report_definition`, with the following limitations:
  - `additional_artifacts` is not supported, this means no integration with Athena or Redshift is possible only with Amazon QuickSight.
  - If Athena or Redshift integration is required, continue using CUR (`legacy_reporting = true`)

- More information: [migrating from CUR to Data Exports (CUR 2.0)](https://docs.aws.amazon.com/cur/latest/userguide/dataexports-migrate.html).

#### Variables

The following variables have been modified:

- `report_definitions`:

  - `additional_schema_elements` has been replaced by:
    - `include_resources`
    - `include_split_cost_allocation_data`
    - `include_manual_discount_compatibility`

  - `refresh_closed_reports` has been removed and is now always `true`.

  - `report_versioning` has been replaced by `overwrite`.

  - `compression` values must now be passed in uppercase.  
    Supported values: `GZIP`, `PARQUET`

  - `format` values must now be passed in uppercase.  
    Supported values: `TEXTORCSV`, `PARQUET`
