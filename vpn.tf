# VPN GATEWAY
# Europe VPN gateway
resource "google_compute_vpn_gateway" "europe_vpn_gateway" {
  region   = "europe-west1"
  name     = "europe-vpn-gateway"
  network  = google_compute_network.europe_network.id
}

# External Static IP Addresses for VPN gateways
resource "google_compute_address" "europe_vpn_ip" {
  name     = "europe-vpn-ip"
  region   = "europe-west1"
}

# VPN tunnel between Asia to Europe
data "google_secret_manager_secret_version" "vpn_secret" {
  secret = "vpn-shared-secret"
  version = "latest"
}

#Forwarding Rules for Europe VPN
resource "google_compute_forwarding_rule" "europe_esp" {
  name        = "europe-esp"
  region      = "europe-west1"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.europe_vpn_ip.address
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "europe_udp500" {
  name        = "europe-udp500"
  region      = "europe-west1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.europe_vpn_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "europe_udp4500" {
  name        = "europe-udp4500"
  region      = "europe-west1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.europe_vpn_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.europe_vpn_gateway.self_link
}

# Reverse VPN Tunnel from Europe to Asia
resource "google_compute_vpn_tunnel" "europe_to_asia_tunnel" {
  name               = "europe-to-asia-tunnel"
  region             = "europe-west1"
  target_vpn_gateway = google_compute_vpn_gateway.europe_vpn_gateway.id
  peer_ip            = google_compute_address.asia_vpn_ip.address
  shared_secret      = data.google_secret_manager_secret_version.vpn_secret.secret_data
  ike_version        = 2

  local_traffic_selector  = ["10.145.11.0/24"]
  remote_traffic_selector = ["192.165.11.0/24"]

  depends_on = [
    google_compute_forwarding_rule.europe_esp,
    google_compute_forwarding_rule.europe_udp500,
    google_compute_forwarding_rule.europe_udp4500
  ]

}



# Asia VPN gateway
resource "google_compute_vpn_gateway" "asia_vpn_gateway" {
  name     = "asia-vpn-gateway"
  network  = google_compute_network.asia_network.id
  region   = "asia-northeast1"
}


resource "google_compute_address" "asia_vpn_ip" {
  name     = "asia-vpn-ip"
  region   = "asia-northeast1"
}

resource "google_compute_vpn_tunnel" "asia_to_europe_tunnel" {
  name               = "asia-to-europe-tunnel"
  region             = "asia-northeast1"
  target_vpn_gateway = google_compute_vpn_gateway.asia_vpn_gateway.id
  peer_ip            = google_compute_address.europe_vpn_ip.address
  shared_secret      = data.google_secret_manager_secret_version.vpn_secret.secret_data
  ike_version        = 2

  local_traffic_selector  = ["192.165.11.0/24"]
  remote_traffic_selector = ["10.145.11.0/24"]

  depends_on = [
    google_compute_forwarding_rule.asia_esp,
    google_compute_forwarding_rule.asia_udp500,
    google_compute_forwarding_rule.asia_udp4500
  ]
}

# Route for Asia to Europe
resource "google_compute_route" "asia_to_europe_route" {
  name                = "asia-to-europe-route"
  network             = google_compute_network.asia_network.id
  dest_range          = "10.145.11.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.asia_to_europe_tunnel.id
  priority            = 1000

}

# Forwarding Rules for Asia VPN
resource "google_compute_forwarding_rule" "asia_esp" {
  name        = "asia-esp"
  region      = "asia-northeast1"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.asia_vpn_ip.address
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "asia_udp500" {
  name        = "asia-udp500"
  region      = "asia-northeast1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.asia_vpn_ip.address
  port_range  = "500"
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}

resource "google_compute_forwarding_rule" "asia_udp4500" {
  name        = "asia-udp4500"
  region      = "asia-northeast1"
  ip_protocol = "UDP"
  ip_address  = google_compute_address.asia_vpn_ip.address
  port_range  = "4500"
  target      = google_compute_vpn_gateway.asia_vpn_gateway.self_link
}


#Route for Europe to Asia
resource "google_compute_route" "europe_to_asia_route" {
  depends_on          = [google_compute_vpn_tunnel.europe_to_asia_tunnel]
  name                = "europe-to-asia-route"
  network             = google_compute_network.europe_network.id
  dest_range          = "192.165.11.0/24"
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.europe_to_asia_tunnel.id
}

