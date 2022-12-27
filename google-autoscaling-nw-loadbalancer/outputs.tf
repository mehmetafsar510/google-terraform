
output "public_ip" {
  value = join("", ["http://", google_compute_forwarding_rule.network-load-balancer.ip_address])
}
