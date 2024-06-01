resource "google_compute_network_peering" "America_europe_peering" {
  name         = "america-to-europe-peering"
  network      = google_compute_network.americas_network.id
  peer_network = google_compute_network.europe_network.id
}

resource "google_compute_network_peering" "europe_america_peering" {
  name         = "europe-to-america-peering"
  network      = google_compute_network.europe_network.id
  peer_network = google_compute_network.americas_network.id
}