variable "region" {
  type = list
  default = [
    "us-central1",
    "us-west1",
    "us-east1",
    "us-east4",
  ]
}

variable "billing_account" {
  type = "string"
}

variable "folder_id" {
  type = "string"
}

variable "auto_create_network" {
  type    = "string"
  default = "false"
}

variable "apis" {
  type = "list"

  default = [
    "compute.googleapis.com",
    "storage-api.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "servicemanagement.googleapis.com",
    "container.googleapis.com",
    "cloudkms.googleapis.com",
    "sql-component.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudkms.googleapis.com",
  ]
}

variable "skip_delete" {
  type    = "string"
  default = "true"
}

variable "type" {
  default = "g1-small"
}

variable "zone_east" {
  type = "list"
  default = [
    "us-east1-b",
    "us-east1-c",
    "us-east1-d",
  ]
}

variable "zone_central" {
  type = "list"
  default = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c",
  ]
}

variable "enable_secondary" {
  type = bool
  default = true
}
variable "ssh_key" {
  default = "awolde:ssh-rsa AAAAB3"
}

variable "nodes" {
  default = "3"
}

variable "rpm_file" {
  default = "./hashitools.rpm"
}

variable "consul_env" {
  type = "map"
  default = {
    "pri" = "primary-consul"
    "sec" = "secondary-consul"
  }
}