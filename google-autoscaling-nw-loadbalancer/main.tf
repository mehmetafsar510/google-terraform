terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.53.0"
    }
  }
}

provider "google" {
  credentials = file("ultimate-vigil-360607-f91006fcdcc3.json")
  project     = "ultimate-vigil-360607"
  region      = "us-central1"
  zone        = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "new-terraform-network"
}
resource "google_compute_autoscaler" "foobar" {
  name    = "my-autoscaler"
  project = "ultimate-vigil-360607"
  zone    = "us-central1-c"
  target  = google_compute_instance_group_manager.foobar.self_link

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

data "template_file" "default" {
  template = file("${path.root}/startup.sh")
  vars = {
    MYDBURI    = google_sql_database_instance.instance.public_ip_address
    DBNAME     = google_sql_database.database.name
    DBUSER     = google_sql_user.users.name
    DBPASSWORD = google_sql_user.users.password
    FLSTIP     = "${google_filestore_instance.instance.networks.0.ip_addresses.0}"
    FLSTNAME   = google_filestore_instance.instance.file_shares.0.name
    ALBDNSNAME = google_compute_forwarding_rule.network-load-balancer.ip_address
  }
}

resource "google_compute_instance_template" "foobar" {
  name           = "my-instance-template"
  machine_type   = "n1-standard-1"
  can_ip_forward = false
  project        = "ultimate-vigil-360607"
  tags           = ["foo", "bar", "allow-lb-service"]

  disk {
    source_image = data.google_compute_image.ubuntu.self_link
  }

  network_interface {
    network = google_compute_network.vpc_network.name
  }

  metadata_startup_script = data.template_file.default.rendered

  metadata = {
    ssh-keys = join("", ["${var.gce_ssh_user}", ":", file("${path.root}/gcloud.pub")])
    foo      = "bar"
  }
  service_account {
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_target_pool" "foobar" {
  name    = "my-target-pool"
  project = "ultimate-vigil-360607"
  region  = "us-central1"
  health_checks = [
    "${google_compute_http_health_check.nlb-hc.name}"
  ]
}

resource "google_compute_instance_group_manager" "foobar" {
  name    = "my-igm"
  zone    = "us-central1-c"
  project = "ultimate-vigil-360607"
  version {
    instance_template = google_compute_instance_template.foobar.self_link
    name              = "primary"
  }

  target_pools       = [google_compute_target_pool.foobar.self_link]
  base_instance_name = "terraform"
}

data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_http_health_check" "nlb-hc" {
  name               = "nlb-health-checks"
  request_path       = "/"
  port               = 80
  check_interval_sec = 10
  timeout_sec        = 3
}


resource "google_compute_forwarding_rule" "network-load-balancer" {
  name                  = "nlb-test"
  region                = "us-central1"
  target                = google_compute_target_pool.foobar.self_link
  port_range            = "80"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
}

resource "random_id" "db_instance_name" {
  byte_length = 2
  keepers = {
    keyname = "thedoctor"
  }
}

resource "google_sql_database_instance" "instance" {
  name                = "my-database-instance-${random_id.db_instance_name.dec}" #you have to change db instance name every creation
  database_version    = "MYSQL_8_0"
  deletion_protection = "false"
  region              = "us-central1"
  project             = "ultimate-vigil-360607"

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "test"
        value = "0.0.0.0/0"
      }
    }
  }
}
resource "google_sql_database" "database" {
  name      = "wordpress"
  instance  = google_sql_database_instance.instance.name
  charset   = "utf8"
  collation = "utf8_general_ci"
}
resource "google_sql_user" "users" {
  name     = "wordpress"
  instance = google_sql_database_instance.instance.name
  host     = "%"
  password = "mypassw0rd"
}