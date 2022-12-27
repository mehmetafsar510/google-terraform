data "template_file" "default" {
  template = file("${path.root}/startup.sh")
  vars = {
    MYDBURI    = google_sql_database_instance.instance.public_ip_address
    DBNAME     = google_sql_database.database.name
    DBUSER     = google_sql_user.users.name
    DBPASSWORD = google_sql_user.users.password
    FLSTIP     = "${google_filestore_instance.instance.networks.0.ip_addresses.0}"
    FLSTNAME   = google_filestore_instance.instance.file_shares.0.name
    ALBDNSNAME = google_compute_global_address.this.address
  }
}
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}
resource "google_compute_instance_template" "this" {
  name        = "${var.name}-${var.deploy_version}"
  description = var.instance_template_description
  
  tags = var.tags

  labels = {
    service = var.name
    version = var.deploy_version
  }

  metadata = {
    ssh-keys = join("", ["${var.gce_ssh_user}", ":", file("${path.root}/gcloud.pub")])
    version = var.deploy_version
  }

  instance_description    = var.instance_description
  machine_type            = var.machine_type
  can_ip_forward          = false
  metadata_startup_script = data.template_file.default.rendered

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = data.google_compute_image.ubuntu.self_link
    boot         = true
    disk_type    = "pd-balanced"
  }

  network_interface {
    network = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.private_subnet_1.name
    access_config {
      
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = data.google_service_account.this.email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
