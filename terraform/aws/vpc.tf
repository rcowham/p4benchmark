
locals {
  name    = "ex-${replace(basename(path.cwd), "_", "-")}"
  subnets = cidrsubnets(var.vpc_cidr, 4, 4, 4, 4)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.0"

  name = "p4-benchmark"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = [local.subnets[0], local.subnets[1]]
  public_subnets  = [local.subnets[2], local.subnets[3]]

  enable_nat_gateway = false
  enable_vpn_gateway = false

}