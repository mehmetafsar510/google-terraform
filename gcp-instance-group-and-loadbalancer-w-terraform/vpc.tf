# create VPC
resource "google_compute_network" "vpc" {
  name = "${var.name}-vpc"
  auto_create_subnetworks = "false" 
  routing_mode = "GLOBAL"
}

# create private subnet
resource "google_compute_subnetwork" "private_subnet_1" {
  provider = google-beta
  purpose = "PRIVATE"
  name = "${var.name}-private-subnet-1"
  ip_cidr_range = var.private_subnet_cidr_1
  network = google_compute_network.vpc.name
  region = var.region
}

# create a public ip for nat service
resource "google_compute_address" "nat-ip" {
  name = "${var.name}-nat-ip"
  project = var.project
  region  = var.region
}
# create a nat to allow private instances connect to internet
resource "google_compute_router" "nat-router" {
  name = "${var.name}-nat-router"
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat-gateway" {
  name = "${var.name}-nat-gateway"
  router = google_compute_router.nat-router.name
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = [ google_compute_address.nat-ip.self_link ]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" 
  depends_on = [ google_compute_address.nat-ip ]
}

