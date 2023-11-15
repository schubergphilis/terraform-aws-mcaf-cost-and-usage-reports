provider "aws" {
  region = "us-east-1"
}

module "kms" {
  source = "github.com/schubergphilis/terraform-aws-mcaf-kms?ref=v0.3.0"
  name   = "example"
}

module "cur" {
  providers = { aws.us-east-1 = aws }

  source      = "../.."
  kms_key_arn = module.kms.arn
}
