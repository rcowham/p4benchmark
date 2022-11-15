
locals {
  subnets = cidrsubnets(var.vpc_cidr, 4, 4, 4, 4)
}

module "vpc" {
  count = var.existing_vpc ? 0 : 1

  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.0"

  name = "p4-benchmark"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = [local.subnets[2], local.subnets[3]]
  public_subnets  = [local.subnets[0], local.subnets[1]]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  # these both must be true to use a S3 VPC endpoint
  enable_dns_hostnames = true
  enable_dns_support   = true

}

module "endpoints" {
  count = var.existing_vpc ? 0 : 1

  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id = module.vpc[0].vpc_id

  endpoints = {
    s3 = {

      service_type    = "Gateway"
      route_table_ids = [module.vpc[0].public_route_table_ids[0]]
      service         = "s3"
      tags            = { Name = "s3-vpc-endpoint" }
    }
  }
}
