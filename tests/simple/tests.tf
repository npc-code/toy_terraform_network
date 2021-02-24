provider "aws" {
  profile = "test"
  region  = "us-east-1"
  alias   = "test"
}

module "under_test" {
  source    = "../.."
  profile   = "test"
  region    = "us-east-1"
  base_cidr = "10.0.0.0/16"

  providers = {
    aws = aws.test
  }
}