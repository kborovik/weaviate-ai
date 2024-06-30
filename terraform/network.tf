###############################################################################
# Network configuration
###############################################################################

resource "google_compute_network" "main" {
  name                    = "main"
  description             = "Default Network"
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_net" {
  name                     = "${var.google_region}-01"
  region                   = var.google_region
  network                  = google_compute_network.main.id
  purpose                  = "PRIVATE"
  private_ip_google_access = true
  ip_cidr_range            = var.google_network.gke_net

  secondary_ip_range {
    range_name    = "gke-pod-${var.app_id}"
    ip_cidr_range = var.google_network.gke_pod
  }
  secondary_ip_range {
    range_name    = "gke-svc-${var.app_id}"
    ip_cidr_range = var.google_network.gke_svc
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

###############################################################################
# Google Managed Services IP ranges
###############################################################################

resource "google_compute_global_address" "google_service_network" {
  name          = "google-managed-services"
  network       = google_compute_network.main.id
  address       = cidrhost(var.google_network.gcp_svc, 0)
  prefix_length = split("/", var.google_network.gcp_svc)[1]
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
}

resource "google_service_networking_connection" "google_service_network" {
  network                 = google_compute_network.main.id
  reserved_peering_ranges = [google_compute_global_address.google_service_network.name]
  service                 = "servicenetworking.googleapis.com"
}

###############################################################################
# Network NAT
###############################################################################

resource "google_compute_address" "cloud_nat" {
  name         = "cloud-nat-${var.app_id}"
  region       = var.google_region
  address_type = "EXTERNAL"
}

resource "google_compute_router" "main" {
  name    = "main"
  region  = var.google_region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "main" {
  name                               = "main"
  region                             = var.google_region
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.cloud_nat.id]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

###############################################################################
# Firewall Rules
###############################################################################

resource "google_compute_firewall" "allow_google_iap" {
  name        = "allow-google-iap"
  description = "Allow Google IAP Services"
  network     = google_compute_network.main.id
  priority    = 100

  source_ranges = [
    "35.235.240.0/20",
  ]

  destination_ranges = [
    var.google_network.project
  ]

  allow {
    protocol = "tcp"
    ports    = ["22", "443"]
  }
}

resource "google_compute_firewall" "allow_google_lb" {
  name        = "allow-google-lb"
  description = "Allow Google Load Balancers"
  network     = google_compute_network.main.id
  priority    = 101

  source_ranges = [
    "35.235.240.0/20",
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  destination_ranges = [
    var.google_network.project
  ]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
