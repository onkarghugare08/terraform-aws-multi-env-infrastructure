env             = "prod"
vpc_cidr        = "10.2.0.0/16"
public_subnets  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnets = ["10.2.3.0/24", "10.2.4.0/24"]
instance_type   = "t3.medium"
instance_count  = 3
allowed_ports   = [80, 443]
bucket_name = "onkar-terra-bucket"