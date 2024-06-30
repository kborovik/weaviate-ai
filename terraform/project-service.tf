###############################################################################
# Enable GCP Project Services
###############################################################################

locals {
  google_project_services = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containersecurity.googleapis.com",
    "iap.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "networkmanagement.googleapis.com",
    "osconfig.googleapis.com",
    "servicenetworking.googleapis.com",
    "storage.googleapis.com",
  ]
}

resource "google_project_service" "main" {
  count                      = length(local.google_project_services)
  service                    = local.google_project_services[count.index]
  disable_dependent_services = true
  disable_on_destroy         = false
}
