terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "remote" {
    organization = "cameronmathis"

    workspaces {
      name = "auburn-on-tour"
    }
  }
}

provider "google" {
  # Update with your project ID
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "firestore" {
  service = "firestore.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions" {
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_scheduler" {
  service = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_build" {
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "errorreporting" {
  service = "clouderrorreporting.googleapis.com"
  disable_on_destroy = false
}

# Firestore configuration
resource "google_firestore_database" "database" {
  name                        = "(default)"
  location_id                 = var.firestore_location
  type                        = "FIRESTORE_NATIVE"
  depends_on                  = [google_project_service.firestore]
}

# Cloud Storage bucket for storing application data
resource "google_storage_bucket" "app_data" {
  name          = "${var.project_id}-app-data"
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30  # 30 days
    }
    action {
      type = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90  # 90 days
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  retention_policy {
    retention_period = 2592000 # 30 days in seconds
  }
}

# Firestore backup schedule
resource "google_firestore_backup_schedule" "default" {
  project  = var.project_id
  database = google_firestore_database.database.name
  
  retention = "1209600s"  # 14 days in seconds
  
  daily_recurrence {
    # Daily backup at 2 AM UTC
  }
  
  depends_on = [google_firestore_database.database]
}

# Make the Cloud Run service public
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_service.auburn_on_tour.location
  project  = google_cloud_run_service.auburn_on_tour.project
  service  = google_cloud_run_service.auburn_on_tour.name
  role     = "roles/run.invoker"
  member   = "allUsers"
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

resource "google_project_iam_member" "app_secret_manager" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
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

# Secret Manager secrets for Twitter API
resource "google_secret_manager_secret" "twitter_api_key" {
  secret_id = "twitter-api-key"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "twitter_api_secret" {
  secret_id = "twitter-api-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "twitter_access_token" {
  secret_id = "twitter-access-token"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "twitter_access_secret" {
  secret_id = "twitter-access-secret"
  replication {
    auto {}
  }
}

# IAM bindings for secrets
resource "google_secret_manager_secret_iam_member" "app_twitter_secrets_access" {
  for_each = toset([
    google_secret_manager_secret.twitter_api_key.id,
    google_secret_manager_secret.twitter_api_secret.id,
    google_secret_manager_secret.twitter_access_token.id,
    google_secret_manager_secret.twitter_access_secret.id
  ])
  
  secret_id = each.key
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Update Cloud Run service to use the application service account
# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_network
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "${var.vpc_network}-subnet"
  ip_cidr_range = "10.0.0.0/28"
  network       = google_compute_network.vpc_network.id
  region        = var.region
}

# VPC Connector
resource "google_vpc_access_connector" "connector" {
  name          = var.vpc_connector_name
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc_network.name
  region        = var.region
}

# Cloud Run service
resource "google_cloud_run_service" "auburn_on_tour" {
  name     = "auburn-on-tour"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.app_service_account.email
      containers {
        image = var.container_image
        
        env {
          name  = "NODE_ENV"
          value = var.environment
        }
        env {
          name  = "GOOGLE_CLOUD_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "TWITTER_API_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.twitter_api_key.secret_id
              key  = "latest"
            }
          }
        }
        env {
          name  = "TWITTER_API_SECRET"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.twitter_api_secret.secret_id
              key  = "latest"
            }
          }
        }
        env {
          name  = "TWITTER_ACCESS_TOKEN"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.twitter_access_token.secret_id
              key  = "latest"
            }
          }
        }
        env {
          name  = "TWITTER_ACCESS_SECRET"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.twitter_access_secret.secret_id
              key  = "latest"
            }
          }
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }

        startup_probe {
          http_get {
            path = "/health"
          }
          initial_delay_seconds = 5
          period_seconds       = 3
        }
      }
      
      # Add timeout for long-running operations
      timeout_seconds = 300
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/client-name" = "terraform"
      "run.googleapis.com/ingress"     = "internal-and-cloud-load-balancing"
      "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
      "run.googleapis.com/vpc-access-egress"    = "all-traffic"
      "autoscaling.knative.dev/maxScale" = "10"
      "run.googleapis.com/cloudsql-instances" = ""  # Add if you need Cloud SQL
    }
  }

  depends_on = [
    google_project_service.cloud_run,
    google_secret_manager_secret.twitter_api_key,
    google_secret_manager_secret.twitter_api_secret,
    google_secret_manager_secret.twitter_access_token,
    google_secret_manager_secret.twitter_access_secret
  ]
}

# Monitoring notification channel (email)
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = var.alert_email_address
  }
}

# Alert policy for high error rates
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate Alert"
  combiner     = "OR"
  conditions {
    display_name = "Error Rate Condition"
    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${google_cloud_run_service.auburn_on_tour.name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      duration        = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = 5
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Service account for Cloud Function and Cloud Scheduler
resource "google_service_account" "scheduler_function_sa" {
  account_id   = "auburn-tour-scheduler"
  display_name = "Auburn Tour Scheduler Service Account"
  description  = "Service account for Cloud Scheduler and Cloud Functions"
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

# Cloud Function
resource "google_storage_bucket" "function_bucket" {
  name          = "${var.project_id}-functions"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "function_archive" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = var.function_source_path # You'll need to provide this

  depends_on = [google_storage_bucket.function_bucket]
}

resource "google_cloudfunctions2_function" "tournament_update" {
  name        = "tournament-update"
  location    = var.region
  description = "Function to update tournament data"

  build_config {
    runtime     = "nodejs18"
    entry_point = "updateTournamentData"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "512M"  # Increased for potential memory requirements
    timeout_seconds    = 540     # Increased for longer operations
    service_account_email = google_service_account.scheduler_function_sa.email
    
    environment_variables = {
      GOOGLE_CLOUD_PROJECT_ID = var.project_id
      NODE_ENV              = var.environment
    }

    secret_environment_variables {
      key        = "TWITTER_API_KEY"
      project_id = var.project_id
      secret     = google_secret_manager_secret.twitter_api_key.secret_id
      version    = "latest"
    }
    secret_environment_variables {
      key        = "TWITTER_API_SECRET"
      project_id = var.project_id
      secret     = google_secret_manager_secret.twitter_api_secret.secret_id
      version    = "latest"
    }
    secret_environment_variables {
      key        = "TWITTER_ACCESS_TOKEN"
      project_id = var.project_id
      secret     = google_secret_manager_secret.twitter_access_token.secret_id
      version    = "latest"
    }
    secret_environment_variables {
      key        = "TWITTER_ACCESS_SECRET"
      project_id = var.project_id
      secret     = google_secret_manager_secret.twitter_access_secret.secret_id
      version    = "latest"
    }
  }
}

# Cloud Scheduler Job
resource "google_cloud_scheduler_job" "tournament_update_job" {
  name        = "tournament-update-job"
  description = "Triggers the tournament update function"
  schedule    = "0 * * * *"  # Runs every hour
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.tournament_update.url

    oidc_token {
      service_account_email = google_service_account.scheduler_function_sa.email
    }
  }

  depends_on = [google_project_service.cloud_scheduler]
}
