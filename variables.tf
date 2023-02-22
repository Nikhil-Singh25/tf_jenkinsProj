variable "CIDR-Production-VPC" {
  type    = string
  default = "10.192.0.0/16"
}

variable "CIDR-Production-subnet" {
  type    = string
  default = "10.192.10.0/24"
}

variable "ingress_ports" {
  type        = list(number)
  description = "list of ingress ports"
  default     = [443, 80, 22]
}
