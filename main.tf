data "aws_caller_identity" "current" {}

locals {
  name = "myapp-${var.env}"
  tags = {
    Environment = var.env
    Project     = "myapp"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source          = "./modules/vpc"
  name            = local.name
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  tags            = local.tags
}

module "security_group" {
  source        = "./modules/security_group"
  name          = local.name
  vpc_id        = module.vpc.vpc_id
  allowed_ports = var.allowed_ports
  tags          = local.tags
}


module "ec2" {
  source             = "./modules/ec2"
  env                = var.env
  name               = local.name
  key_name           = "${var.env}-terra-key"
  instance_type      = var.instance_type
  instance_count     = var.instance_count
  subnet_ids         = module.vpc.public_subnet_ids # <-- list now
  security_group_ids = [module.security_group.sg_id]
  tags               = local.tags
}

module "dynamodb" {
  source       = "./modules/dynamodb"
  table_name   = "${local.name}-table"
  billing_mode = var.billing_mode
  tags         = local.tags
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = "${var.bucket_name}-${var.env}"
  tags        = local.tags
}
