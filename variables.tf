variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod."
  }
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "instance_type" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "allowed_ports" {
  description = "TCP ports open to the internet"
  type        = list(number)
}


variable "billing_mode" {
  type    = string
  default = "PAY_PER_REQUEST"
}

variable "bucket_name" {
  description = "Base name for the S3 bucket (globally unique, lowercase)"
  type        = string
}