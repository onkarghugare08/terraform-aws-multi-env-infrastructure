terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }

# For the backend configuration, you can uncomment and configure the following block if you want to use S3 for remote state management:
 # backend "s3" {
  #  bucket         = "onkar-terra-state-1817"
  #  key            = "myapp/terraform.tfstate"
  #  region         = "us-west-2"
  #  dynamodb_table = "terra-state-lock"
  #  encrypt        = true
 # }
}