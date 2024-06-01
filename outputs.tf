# Outputs
output "Task_3" {
  value = "IP Addresses:"
}

output "europe_vpn_ip_address" {
  value =  google_compute_address.europe_vpn_ip.address
}

output "asia_vpn_ip_address" {
  value = google_compute_address.asia_vpn_ip.address
}

output "europe_vm_internal_ip" {
  value = google_compute_instance.europe_vm.network_interface[0].network_ip
}

