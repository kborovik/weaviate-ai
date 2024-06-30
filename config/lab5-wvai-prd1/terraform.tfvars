google_project = "lab5-wvai-prd"
google_region  = "us-east5"
google_network = {
  project = "10.129.0.0/16",
  gke_net = "10.129.16.0/20",
  gke_pod = "10.129.32.0/20",
  gke_svc = "10.129.48.0/20",
  gcp_svc = "10.129.240.0/20"
}
