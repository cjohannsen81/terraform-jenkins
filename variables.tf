variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_amis" {
  default = {
    us-east-1 = "ami-08bc77a2c7eb2b1da"
  }
}

variable "keypair" {
  default = "/Users/cjohannsen/.ssh/cjohannsen1981.pem"
}

variable "keyname" {
  default = "cjohannsen1981"
}
