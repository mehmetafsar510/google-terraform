resource "google_filestore_instance" "instance" {
  name = "myfilestore"
  zone = var.zone
  tier = "STANDARD"

  file_shares {
    capacity_gb = 1024
    name        = "share1"
  }

  networks {
    network = google_compute_network.vpc_network.name
    modes   = ["MODE_IPV4"]
  }
}