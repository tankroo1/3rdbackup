#americas networks and Subnets
resource "google_compute_network" "americas_network" {
  name                                      = "americas-network"
  auto_create_subnetworks                   =  false
}

  resource "google_compute_subnetwork" "americas_subnet1" {
  name          = "americas-subnet1"
  network       = google_compute_network.americas_network.id
  ip_cidr_range = "172.15.21.0/24"
  region        = "us-west1"
  private_ip_google_access = true
  }

  resource "google_compute_subnetwork" "americas_subnet2" {
  name          = "americas-subnet2"
  network       = google_compute_network.americas_network.id
  ip_cidr_range = "172.15.22.0/24"
  region        = "us-east1"
  private_ip_google_access = true
  }

  resource "google_compute_firewall" "america_to_europe_http" {
  name    = "america-to-europe-http"
  network = google_compute_network.americas_network.id

  allow {
    protocol = "tcp"
    ports = ["80", "22"]
  }


  source_ranges = ["0.0.0.0/0", "35.235.240.0/20"]
  target_tags   = ["america-http-server", "iap-ssh-allowed"]
}

resource "google_compute_instance" "america_vm1" {
  depends_on   = [google_compute_subnetwork.americas_subnet1]
  name         = "america-vm1"
  machine_type = "e2-medium"
  zone         = "us-west1-a"


  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.americas_network.id
    subnetwork = google_compute_subnetwork.americas_subnet1.id

    access_config {
      //Not assigning a public IP
    }
  }

  tags = ["america-http-server", "iap-ssh-allowed"]

}

resource "google_compute_instance" "america_vm2" {
  depends_on   = [google_compute_subnetwork.americas_subnet2]
  name         = "america-vm2"
  machine_type = "e2-medium"
  zone         = "us-east1-b"


  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.americas_network.id
    subnetwork = google_compute_subnetwork.americas_subnet2.id

    access_config {
      //Not assigning a public IP
    }
  }

  tags = ["america-http-server", "iap-ssh-allowed"]

}