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
  default     = "nam5"  # North America multi-region
}

variable "environment" {
  description = "The environment (production, development, etc.)"
  type        = string
  default     = "production"
}

variable "container_image" {
  description = "The container image to deploy to Cloud Run"
  type        = string
}

variable "function_source_path" {
  description = "Path to the zipped source code for the Cloud Function"
  type        = string
  default     = "../function/function-source.zip"
}

variable "alert_email_address" {
  description = "Email address to receive monitoring alerts"
  type        = string
}

variable "vpc_connector_name" {
  description = "Name of the VPC connector to use"
  type        = string
  default     = "auburn-vpc-connector"
}

variable "vpc_network" {
  description = "Name of the VPC network"
  type        = string
  default     = "auburn-network"
}
