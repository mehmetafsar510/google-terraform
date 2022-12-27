resource "google_compute_network" "vpc_network" {
  name                    = format("%s", "${var.company}-${var.env}-vpc")
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}
resource "google_compute_subnetwork" "public_subnet" {
  name          = format("%s", "${var.company}-${var.env}-pub-net")
  ip_cidr_range = var.uc1_public_subnet
  network       = google_compute_network.vpc_network.name
  region        = var.region
}
resource "google_compute_subnetwork" "private_subnet" {
  name          = format("%s", "${var.company}-${var.env}-pri-net")
  ip_cidr_range = var.uc1_private_subnet
  network       = google_compute_network.vpc_network.name
  region        = var.region
}
resource "google_compute_firewall" "allow-internal" {
  name     = "${var.company}-fw-allow-internal"
  network  = google_compute_network.vpc_network.name
  priority = 65534
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = [
    "${var.uc1_private_subnet}",
    "${var.uc1_public_subnet}"
  ]
}

resource "google_compute_firewall" "allow-http" {
  name        = "${var.company}-fw-allow-http"
  network     = google_compute_network.vpc_network.name
  priority    = 65534
  source_tags = ["web"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = [
    "0.0.0.0/0"
  ]
}

resource "google_compute_firewall" "allow-https" {
  name        = "${var.company}-fw-allow-https"
  network     = google_compute_network.vpc_network.name
  priority    = 65534
  source_tags = ["web"]
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  source_ranges = [
    "0.0.0.0/0"
  ]
}

resource "google_compute_firewall" "allow-ssh" {
  name     = "${var.company}-fw-allow-ssh"
  network  = google_compute_network.vpc_network.name
  priority = 65534
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = [
    "0.0.0.0/0"
  ]
}

resource "google_compute_address" "static-ip-address" {
  name = "my-static-ip-address"
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
  }
}

resource "google_compute_instance" "vm_instance" {
  name                    = "terraform-instance"
  machine_type            = "e2-micro"
  metadata_startup_script = data.template_file.default.rendered #metadata_startup_script = file("${path.root}/startup.sh")
  metadata = {
    ssh-keys = join("", ["${var.gce_ssh_user}", ":", file("${path.root}/gcloud.pub")])
  }
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }
  tags = ["web"]

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name

    access_config {
      nat_ip = google_compute_address.static-ip-address.address
    }
  }
}

resource "random_id" "db_instance_name" {
  byte_length = 2
  keepers = {
    keyname = "thedoctor"
  }
}

resource "google_sql_database_instance" "instance" {
  name             = "my-database-instance-${random_id.db_instance_name.dec}" #you have to change db instance name every creation
  database_version = "MYSQL_8_0"
  region           = var.region
  project          = var.project
  depends_on = [
    google_compute_address.static-ip-address
  ]
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = google_compute_address.static-ip-address.name
        value = google_compute_address.static-ip-address.address
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
  password = var.password
}