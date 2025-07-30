variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The default Google Cloud region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The default Google Cloud zone"
  type        = string
  default     = "us-central1-a"
}

variable "firestore_location" {
  description = "The location for the Firestore database"
  type        = string
  default     = "nam5"
}
