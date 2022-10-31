provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Owner       = var.owner
      Product     = "Perforce P4 Benchmark"
      Terraform   = "true"
    }
  }
}