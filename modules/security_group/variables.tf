variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_ports" {
  type = list(number)
}

variable "tags" {
  type = map(string)
}
