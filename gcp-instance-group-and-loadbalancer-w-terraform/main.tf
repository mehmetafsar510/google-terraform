terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.65.0"
    }
    
    google-beta = {
      source = "hashicorp/google-beta"
      version = "3.65.0"
    }
  }

  required_version = "~> 0.15"
}

#terraform {
#  backend "gcs" {
#    bucket      = "tf-deployment-state"
#    prefix      = "production"
#  }
#}

provider "google" {
  credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

data "google_service_account" "this" {
  account_id = var.project_name
}

data "google_compute_instance_template" "generic" {
  project     = var.project
  name        = "${var.name}-${var.deploy_version}"
  most_recent = true

  depends_on = [ google_compute_instance_template.this ]
}

data "google_compute_instance_group" "this" {
  name = var.name
}

data "google_compute_health_check" "health_check" {
  name = "${var.name}-healthcheck"
}
