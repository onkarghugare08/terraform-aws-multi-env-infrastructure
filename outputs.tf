output "environment" {
  value = var.env
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}
output "ssh_key_name" {
  value = module.ec2.key_name
}

output "ec2_instances" {
  description = "Name => id / public ip / private ip"
  value       = module.ec2.instances
}

output "ssh_commands" {
  value = [
    for ip in module.ec2.public_ips :
    "ssh -i keys/${module.ec2.key_name}.pem ubuntu@${ip}"
  ]
}

output "dynamodb_table" {
  value = module.dynamodb.table_name
}

output "s3_bucket" {
  value = module.s3.bucket_name
}