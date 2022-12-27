# allow http traffic
resource "google_compute_firewall" "allow-http" {
  name = "${var.name}-fw-allow-http"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags = var.tags
}# allow https traffic
resource "google_compute_firewall" "allow-https" {
  name = "${var.name}-fw-allow-https"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  target_tags = var.tags
}# allow ssh traffic
resource "google_compute_firewall" "allow-ssh" {
  name = "${var.name}-fw-allow-ssh"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = var.tags
}# allow rdp traffic
resource "google_compute_firewall" "allow-rdp" {
  name = "${var.name}-fw-allow-rdp"
  network = "${google_compute_network.vpc.name}"
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
  target_tags = var.tags
}

resource "google_compute_firewall" "this" {
  name    = "${var.name}-allow-healthcheck"
  network = "${google_compute_network.vpc.name}"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  
  priority = 1000
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags = var.tags
}

resource "google_compute_firewall" "allow-internal" {
  name    = "${var.name}-fw-allow-internal"
  network = "${google_compute_network.vpc.name}"
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
    "${var.private_subnet_cidr_1}"
  ]
}