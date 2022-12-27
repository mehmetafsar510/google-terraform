variable "project" {}

variable "credentials_file" {}

variable "password" {}

variable "gce_ssh_user" {
  default = "thedoctor"
}

variable "region" {
    type = string
    description = "Infrastructure Region"
    default = "us-central1"
}

variable "project_name" {
    type = string
    description = "Project Name"
    default = "ultimate-vigil-360607"
}

variable "zone" {
    type = string
    description = "Zone"
    default = "us-central1-c"
}

variable "name" {
    type = string
    description = "The base name of resources"
    default = "wordpress"
}

variable "deploy_version" {
    type = string
    description = "Deployment Version"
    default = "1"
}

variable "tags" {
    type = list
    description = "Network Tags for resources"
    default = [ "wordpress-app" ]
}

variable "machine_type" {
    type = string
    description = "VM Size"
    default = "e2-medium"
}
# define private subnet
variable "private_subnet_cidr_1" {
  type = string
  description = "private subnet CIDR 1"
}


variable "minimum_vm_size" {
    type = number
    description = "Minimum VM size in Instance Group"
    default = 2
}

variable "instance_description" {
    type = string
    description = "Description assigned to instances"
    default = "This template is used to create nginx-app server instances"
}

variable "instance_group_manager_description" {
    type = string
    description = "Description of instance group manager"
    default = "Instance group for nginx-app server"
}

variable "instance_template_description" {
    type = string
    description = "Description of instance template"
    default = "nginx-app server template"
}
