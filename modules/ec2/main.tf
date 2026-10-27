data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh
  tags       = var.tags
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.root}/keys/${var.key_name}.pem"
  file_permission = "0400"
}

resource "aws_instance" "this" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = element(var.subnet_ids, count.index)
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = var.security_group_ids

  tags = merge(var.tags, {
    Name = "${var.env}-server-${count.index + 1}"
  })
}