terraform {
    required_version = ">=1.2"

    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~>5.0"
      }
    }
}

# NOTE: This project is configured to run against LocalStack (http://localhost:4566)
# for local testing and cost saving.
provider "aws" {
  region = "eu-central-1"

# Dummy credentials for LocalStack (not real AWS secrets)
  access_key = "test"
  secret_key = "test"

# Skip AWS authentication checks since LocalStack runs locally
  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_region_validation = true
  skip_requesting_account_id = true

# S3 path-style URL required by LocalStack
  s3_use_path_style = true

# Redirect AWS API calls to LocalStack port 4566
  endpoints {
    ec2 = "http://localhost:4566"
    s3 = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
    elb = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
  }
}