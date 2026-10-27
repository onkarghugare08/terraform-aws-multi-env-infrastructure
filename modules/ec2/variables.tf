variable "name" {
  type = string
}

variable "env" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "instance_count" {
  type = number
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "key_name" {
  type = string
}
