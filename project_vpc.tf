//resource "google_project" "vault_project" {
//  name                = "${var.project_name}"
//  project_id          = "${var.project_name}-${random_string.suffix.result}"
//  folder_id           = "${var.folder_id}"
//  billing_account     = "${var.billing_account}"
//  auto_create_network = "${var.auto_create_network}"
//  skip_delete         = "${var.skip_delete}"
//}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_project_service" "services" {
  //might need to change this to tf 0.12 for_each
  count              = length(var.apis)
  service            = element(var.apis, count.index)
  project            = var.project
  disable_on_destroy = false
}

variable "project" {
  default = ""
}
module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 1.4.0"
  project_id   = var.project
  network_name = "${var.project}-ntk"

  subnets = [
    {
      subnet_name           = "sub1"
      subnet_ip             = "10.11.0.0/16"
      subnet_region         = var.region[0]
      subnet_private_access = "true"
    },
    {
      subnet_name           = "sub2"
      subnet_ip             = "10.12.0.0/16"
      subnet_region         = var.region[2]
      subnet_private_access = "true"
    },
  ]
  secondary_ranges = {
    "sub1" = []
    "sub2" = []
  }
}

resource "google_compute_firewall" "allow_consul_vault" {
  name    = "allow-cv"
  network = module.vpc.network_name
  project = var.project

  allow {
    //    protocol = "all"
    protocol = "tcp"
    //    ports    = []
    ports = ["8200", "8500", "8300", "8301", "8302", "22", "8201"]
  }
  allow {
    protocol = "udp"
    ports    = ["8301", "8302", "8600"]
  }

  target_tags   = ["allow-cv"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_forwarding_rule" "vault_primary_fr" {
  project               = var.project
  region                = var.region[0]
  load_balancing_scheme = "EXTERNAL"
  name                  = "vault-pri-forwarding-rule"
  target                = google_compute_target_pool.vault_pri_tp.self_link
  port_range            = 8200
}

resource "google_compute_target_pool" "vault_pri_tp" {
  name    = "vault-pri-pool"
  project = var.project
  region  = var.region[0]

  instances = google_compute_instance.vault_primary[*].self_link

  health_checks = [
    google_compute_http_health_check.vault_hc.name,
  ]
}

resource "google_compute_http_health_check" "vault_hc" {
  project            = var.project
  name               = "vault-check"
  request_path       = "/v1/sys/health"
  check_interval_sec = 2
  timeout_sec        = 1
  port               = 8200
}

resource "google_compute_forwarding_rule" "vault_secondary_fr" {
  count = var.enable_secondary ? var.nodes : 0
  project               = var.project
  region                = var.region[2]
  load_balancing_scheme = "EXTERNAL"
  name                  = "vault-sec-forwarding-rule"
  target                = google_compute_target_pool.vault_sec_tp[0].self_link
  port_range            = 8200
}

resource "google_compute_target_pool" "vault_sec_tp" {
  count = var.enable_secondary ? var.nodes : 0
  name    = "vault-sec-pool"
  project = var.project
  region  = var.region[2]

  instances = google_compute_instance.vault_secondary[*].self_link

  health_checks = [
    google_compute_http_health_check.vault_hc.name,
  ]
}