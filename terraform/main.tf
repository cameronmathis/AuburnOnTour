terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket = "auburn-on-tour-terraform-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "storage" {
  project            = var.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_build" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_scheduler" {
  project            = var.project_id
  service            = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions" {
  project            = var.project_id
  service            = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "firestore" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_resource_manager" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifact_registry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  project            = var.project_id
  service            = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  project            = var.project_id
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

# GCS bucket resource
resource "google_storage_bucket" "terraform_state" {
  name                        = "auburn-on-tour-terraform-state"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Service Accounts
resource "google_service_account" "app_service_account" {
  account_id   = "auburn-on-tour-app"
  display_name = "Auburn On Tour Application Service Account"
  description  = "Service account for the main application"
}

resource "google_service_account" "ci_cd_service_account" {
  account_id   = "auburn-on-tour-cicd"
  display_name = "Auburn On Tour CI/CD Service Account"
  description  = "Service account for CI/CD pipelines"
}

resource "google_service_account" "scheduler_function_sa" {
  account_id   = "auburn-tour-scheduler"
  display_name = "Auburn Tour Scheduler Service Account"
  description  = "Service account for Cloud Scheduler and Cloud Functions"
}

# IAM roles for the application service account
resource "google_project_iam_member" "app_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

resource "google_project_iam_member" "app_storage" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# IAM roles for the CI/CD service account
resource "google_project_iam_member" "cicd_cloud_run" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${google_service_account.ci_cd_service_account.email}"
}

resource "google_project_iam_member" "cicd_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.ci_cd_service_account.email}"
}

resource "google_project_iam_member" "cicd_service_accounts" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.ci_cd_service_account.email}"
}

resource "google_project_iam_member" "cicd_cloud_functions" {
  project = var.project_id
  role    = "roles/cloudfunctions.admin"
  member  = "serviceAccount:${google_service_account.ci_cd_service_account.email}"
}

# IAM roles for the scheduler/function service account
resource "google_project_iam_member" "function_firestore" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.scheduler_function_sa.email}"
}

resource "google_project_iam_member" "function_invoker" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_function_sa.email}"
}

# Cloud Scheduler Job
resource "google_cloud_scheduler_job" "auburn_on_tour_job" {
  name        = "auburn-on-tour-job"
  description = "Triggers the auburn on tour function"
  schedule    = "0 * * * *"
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${var.project_id}.cloudfunctions.net/auburn-on-tour"

    oidc_token {
      service_account_email = google_service_account.scheduler_function_sa.email
    }
  }

  depends_on = [google_project_service.cloud_scheduler]
}

# Firestore database config
resource "google_firestore_database" "database" {
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"
  depends_on  = [google_project_service.firestore]
}
