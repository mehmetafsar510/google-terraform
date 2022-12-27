output "nat_ip_address" {
  value = google_compute_address.nat-ip.address
}

output "public_ip" {
  value = join("", ["https://", google_compute_global_address.this.address])
}


output "DNS" {
  value = join("", ["https://", "googlecloud.westerops.com"])
}