/*You must complete the following scenerio.

A European gaming company is moving to GCP.  It has the following requirements in it's first stage migration to the Cloud:

A) You must choose a region in Europe to host it's prototype gaming information.  This page must only be on a RFC 1918 Private 10 net and can't be accessible from the Internet.
B) The Americas must have 2 regions and both must be RFC 1918 172.16 based subnets.  They can peer with HQ in order to view the homepage however, they can only view the page on port 80.
C) Asia Pacific region must be choosen and it must be a RFC 1918 192.168 based subnet.  This subnet can only VPN into HQ.  Additionally, only port 3389 is open to Asia. No 80, no 22.

Deliverables.
1) Complete Terraform for the entire solution.
2) Git Push of the solution to your GitHub.
3) Screenshots showing how the HQ homepage was accessed from both the Americas and Asia Pacific.?*/

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.28.0"
    }
  }
}

provider "google" {
  region      = "us-east1"
  project     = "viceroygunray"
  zone        = "us-east1-b"
  credentials = "viceroygunray-712c1dbcf854.json"
}

#European HQ network and Subnet
resource "google_compute_network" "europe_network" {
  name                    = "europe-network"
  auto_create_subnetworks =  false
  routing_mode =  "REGIONAL"
  mtu = 1460
  }


#Europe's subnet to identify it as target for HTTP traffic

  resource "google_compute_subnetwork" "europe_subnet" {
  name          = "europe-subnet"
  network       =  google_compute_network.europe_network.id
  ip_cidr_range = "10.145.11.0/24"
  region        = "europe-west1"
  private_ip_google_access = true
  }

  resource "google_compute_firewall" "europe_http" {
  name    = "europe-http"
  network = google_compute_network.europe_network.id

  allow {
    protocol = "tcp"
    ports = ["80"]
  }


  source_ranges = ["10.145.11.0/24", "172.15.21.0/24", "172.15.22.0/24", "192.165.11.0/24"]
  target_tags   = ["europe-http-server", "america-http-server", "asia-rdp-server"]
}

resource "google_compute_instance" "europe_vm" {
  depends_on   = [google_compute_subnetwork.europe_subnet]
  name         = "europe-vm"
  machine_type = "e2-medium"
  zone         = "europe-west1-b"


  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.europe_network.id
    subnetwork = google_compute_subnetwork.europe_subnet.id

    access_config {
      //Not assigning a public IP
    }
  }

  metadata = {
    metadata_startup_script = file("${path.module}/startup-script.sh")
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  tags = ["europe-http-server"]

}