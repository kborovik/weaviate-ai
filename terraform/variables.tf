###############################################################################
# General project settings
###############################################################################

variable "app_id" {
  description = "Application ID to identify GCP resources"
  type        = string
  default     = "wvai"
}

variable "google_project" {
  description = "GCP Project Id"
  type        = string
  default     = null
}

variable "google_region" {
  description = "Default GCP region"
  type        = string
  default     = null
}

variable "google_network" {
  description = "Google network address"
  type = object({
    project = string
    gke_net = string
    gke_pod = string
    gke_svc = string
    gcp_svc = string
  })
  default = null
}

variable "google_gke_subnet" {
  description = "Google GKE sub-network address"
  type        = string
  default     = null
}

variable "gke_machine_type" {
  description = "GKE Node Size"
  type        = string
  default     = "e2-highmem-2"
}
