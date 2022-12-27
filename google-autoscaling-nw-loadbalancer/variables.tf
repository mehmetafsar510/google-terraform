variable "project" {}

variable "credentials_file" {}

variable "password" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}
variable "env" {
  default = "dev"
}
variable "company" {
  default = "finartz"
}

variable "uc1_private_subnet" {
  default = "10.26.1.0/24"
}

variable "uc1_public_subnet" {
  default = "10.26.2.0/24"
}

variable "gce_ssh_user" {
  default = "thedoctor"
}

