terraform {
  backend "s3" {
    bucket         = "cloudview-tfstate"
    key            = "cloudview.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "cloudview-tf-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

data "aws_region" "current" {}