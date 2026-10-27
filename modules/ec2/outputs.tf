output "key_name" {
  value = aws_key_pair.this.key_name
}

output "instance_ids" {
  value = aws_instance.this[*].id
}

output "public_ips" {
  value = aws_instance.this[*].public_ip
}

output "private_ips" {
  value = aws_instance.this[*].private_ip
}

output "instances" {
  value = {
    for i in aws_instance.this :
    i.tags["Name"] => {
      id         = i.id
      public_ip  = i.public_ip
      private_ip = i.private_ip
    }
  }
}