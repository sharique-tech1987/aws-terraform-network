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
    us-west-1 = "ami-08e2ed24aa233a8cb"
  }
}

variable "USER" {
  default = "ec2-user"
}