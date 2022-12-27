resource "google_filestore_instance" "instance" {
  name = "my-filestore-instance"
  zone = "us-central1-b"
  tier = "STANDARD"

  file_shares {
    capacity_gb = 1024
    name        = "myfilestoreshare"
  }

  networks {
    network = "default"
    modes   = ["MODE_IPV4"]
  }
}