variable "environment" {
  type = string
  default = "management"
}

data "aws_s3_bucket" "log_bucket" {
  bucket = "s3-accesslogs-sydney-<acccountnumber>"
}

module "terraform-state" {
  source = "../modules/terraform-state"
  environment = "${var.environment}"
  s3_log_bucket_id = data.aws_s3_bucket.log_bucket.id
}

module "vanta" {
  source      = "../modules/vanta"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "storagelens" {
    bucket = "storagelensbucket-<accountnumber>"
}
resource "aws_s3control_storage_lens_configuration" "storagelens" {
  config_id = "storagelensadvanced"

  storage_lens_configuration {
    enabled = true
    aws_org {
      arn = "arn:aws:organizations::<accountnumber>:organization/<ou-id>"
    }
    account_level {
      activity_metrics {
        enabled = true
      }
      advanced_cost_optimization_metrics {
        enabled = true
      }
      advanced_data_protection_metrics {
        enabled = true
      }
      detailed_status_code_metrics {
        enabled = true
      }
      bucket_level {
        activity_metrics {
          enabled = true
        }
        advanced_cost_optimization_metrics {
          enabled = true
        }
        advanced_data_protection_metrics {
          enabled = true
        }
        detailed_status_code_metrics {
          enabled = true
        }
        prefix_level {
          storage_metrics {
            enabled = true
            selection_criteria {
              delimiter                    = "/"
              max_depth                    = 5 
              min_storage_bytes_percentage = 1.23
            }
          }
        }
      }
    }

    data_export {
      cloud_watch_metrics {
        enabled = true
      }

      s3_bucket_destination {
        account_id            = data.aws_caller_identity.current.account_id
        arn                   = aws_s3_bucket.storagelens.arn
        format                = "CSV"
        output_schema_version = "V_1"

        encryption {
          sse_s3 {}
        }
      }
    }
  }
}
