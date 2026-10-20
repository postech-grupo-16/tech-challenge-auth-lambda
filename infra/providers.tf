terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    # Reaproveita o bucket de state criado por tech-challenge-infra-k8s
    # (precisa ser aplicado primeiro). Troque se usar outro bucket.
    bucket = "tech-challenge-infra-k8s-gabrielfsg"
    key    = "auth-lambda/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
