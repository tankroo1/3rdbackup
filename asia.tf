#Asia-Pacific Network and Subnet
resource "google_compute_network" "asia_network" {
  name                                      = "asia-network"
  auto_create_subnetworks                   =  false
}

  resource "google_compute_subnetwork" "asia_subnet" {
  name          = "asia-subnet"
  ip_cidr_range = "192.165.11.0/24"
  region        = "asia-northeast1"
  network       = google_compute_network.asia_network.id
  private_ip_google_access = true
  }

#firewall Rule for allowing RDP only from Asia
  resource "google_compute_firewall" "asia_allow_rdp" {
  name    = "asia-allow-rdp"
  network = google_compute_network.asia_network.id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }


  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["asia-rdp-server"]
}

resource "google_compute_instance" "asia_vm1" {
  depends_on   = [google_compute_subnetwork.asia_subnet]
  name         = "asia-vm"
  machine_type = "n2-standard-4"
  zone         = "asia-northeast1-c"


  boot_disk {
    initialize_params {
      image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20240415"
    }
  }

  network_interface {
    network    = google_compute_network.asia_network.id
    subnetwork = google_compute_subnetwork.asia_subnet.id

    access_config {
      //Not assigning a public IP
    }
  }

  tags = ["asia-rdp-server"]

}