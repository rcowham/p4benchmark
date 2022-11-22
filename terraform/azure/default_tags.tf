locals {
  tags = {
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}