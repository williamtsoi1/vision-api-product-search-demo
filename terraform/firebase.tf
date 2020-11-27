provider "google-beta" {
  project     = var.project_id
  region      = var.region
  credentials = base64decode(google_service_account_key.firebase_key.private_key)
}

resource "google_service_account" "firebase" {
  account_id   = "firebase"
  display_name = "FireBase Service Account"
  depends_on = [
    google_project_service.firebase,
  ]
}

resource "google_project_iam_member" "service_account_firebase_admin" {
  role   = "roles/owner"
  member = "serviceAccount:${google_service_account.firebase.email}"
}

resource "google_service_account_key" "firebase_key" {
  service_account_id = google_service_account.firebase.name
}

resource "google_firebase_project" "default" {
  provider = google-beta
  project = google_project.my_project.project_id

  depends_on = [
    google_project_service.firebase,
    google_project_iam_member.service_account_firebase_admin,
    google_service_account_key.firebase_key,
  ]
}

# Sets the default location for resources 
resource "google_firebase_project_location" "default" {
  provider = google-beta
  project = google_firebase_project.default.project
  location_id = var.app_engine_region
}

# This enables Firestore in the project
resource "google_app_engine_application" "app" {
    project = google_project.my_project.project_id
    location_id = var.app_engine_region
    database_type = "CLOUD_FIRESTORE"
}

