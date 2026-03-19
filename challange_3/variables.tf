variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zone"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "VM Machine Type"
  type        = string
  default     = "e2-micro"
}

variable "instance_name" {
  description = "VM Name"
  type        = string
  default     = "challange-3-webserver"
}