terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.52.0"
      configuration_aliases = [aws.us-east-1]
    }
  }
  required_version = ">= 1.2.0"
}
