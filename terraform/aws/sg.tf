locals {
  vpc_id = var.existing_vpc ? var.existing_vpc_id : module.vpc[0].vpc_id
}


module "helix_core_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.8.0"

  name        = "helix-core-${var.environment}"
  description = "Security group for Helix Core services"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 1666
      to_port     = 1666
      protocol    = "tcp"
      description = "Helix Core 1666"
      cidr_blocks = var.ingress_cidrs_1666
    },
    {
      from_port   = 1666
      to_port     = 1666
      protocol    = "tcp"
      description = "Helix Core 1666"
      cidr_blocks = var.vpc_cidr
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Helix Core 1666"
      cidr_blocks = var.ingress_cidrs_22
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = var.vpc_cidr
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "Allow all outbound to the internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}


module "locust_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.8.0"

  name        = "locust-${var.environment}"
  description = "Security group for Locust services"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Locust HTTP"
      cidr_blocks = var.ingress_cidrs_locust
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = var.ingress_cidrs_22
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = var.vpc_cidr
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "Allow all outbound to the internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}


module "driver_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.8.0"

  name        = "locust-${var.environment}"
  description = "Security group for p4 benchmark driver"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH"
      cidr_blocks = var.ingress_cidrs_22
    },
    {
      from_port   = 5557
      to_port     = 5557
      protocol    = "tcp"
      description = "Allow locust clients to report to the locust master"
      cidr_blocks = var.vpc_cidr
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "Allow all outbound to the internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

resource "aws_security_group_rule" "grafana" {
  count = var.install_p4prometheus ? 1 : 0

  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.ingress_cidrs_3000
  security_group_id = module.driver_sg.security_group_id
}



