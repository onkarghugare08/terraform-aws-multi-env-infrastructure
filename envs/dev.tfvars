env             = "dev"
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
instance_type   = "t3.micro"
instance_count  = 2
allowed_ports = [22, 80, 443]
bucket_name = "onkar-terra-bucket"