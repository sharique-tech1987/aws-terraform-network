variable "REGION" {
  default = "us-west-1"
}

variable "ZONE1" {
  default = "us-west-1a"
}

variable "ZONE2" {
  default = "us-west-1b"
}

variable "AMIS" {
  type = map(any)
  default = {
    us-east-2 = "ami-01103fb68b3569475"
    us-east-1 = "ami-04cb4ca688797756f"
  }
}

variable "USER" {
  default = "ec2-user"
}