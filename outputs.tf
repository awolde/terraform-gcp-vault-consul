output "bucket" {
  value = google_storage_bucket.repo.name
}

output "vault_sec_node_ips" {
  value = [
    for ip in google_compute_instance.vault_secondary[*].network_interface[0].network_ip :
    "http://${ip}:8200"
  ]
}

output "vault_pri_node_ips" {
  value = [
    for ip in google_compute_instance.vault_primary[*].network_interface[0].network_ip :
    "http://${ip}:8200"
  ]
}

output "consul_pri_ips" {
  value = [
    for ip in google_compute_instance.consul_primary[*].network_interface[0].network_ip :
    "http://${ip}:8500"
  ]
}

output "consul_sec_ips" {
  value = [
    for ip in google_compute_instance.consul_secondary[*].network_interface[0].network_ip :
    "http://${ip}:8500"
  ]
}

output "connect" {
  value = "sshuttle -r ${google_compute_instance.jump_box.network_interface.0.access_config.0.nat_ip} 10.0.0.0/8"
}

output "primary_lb" {
  value = "http://${google_compute_forwarding_rule.vault_primary_fr.ip_address}:8200"
}

output "secondary_lb" {
  value = [
    for ip in google_compute_forwarding_rule.vault_secondary_fr.*.ip_address :
      "http://${ip}:8200"
  ]
}