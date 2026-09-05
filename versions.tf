terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State remoto usado pelo repositório Infraestrutura-Kubernetes-Terraform
  # (infra/gateway.tf) para ler os outputs desta Lambda via terraform_remote_state.
  backend "s3" {
    bucket = "meu-bucket-terraform-state"
    key    = "auth-service/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
