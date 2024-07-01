
variable "availability_zone" {
  default = "eu-west-1a"
  type    = string
}


variable "aws_region" {
  description = "The AWS region to deploy resources in"
  default     = "eu-west-1a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}




