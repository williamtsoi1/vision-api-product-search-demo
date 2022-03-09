# Service account for Vision API Product Search
resource "google_service_account" "product_search" {
    account_id = "vision-product-search"
    display_name = "Product Search"
    depends_on = [
        google_project.my_project
    ]
}

resource "google_project_iam_binding" "project" {
  project = google_project.my_project.project_id
  role    = "roles/editor"

  members = [
    "serviceAccount:${google_service_account.product_search.email}",
    "serviceAccount:${google_project.my_project.number}@cloudservices.gserviceaccount.com",
    "serviceAccount:${google_project.my_project.number}-compute@developer.gserviceaccount.com",
  ]
}

resource "google_service_account_key" "product_search" {
  service_account_id = google_service_account.product_search.name
}

# Gives the App Engine service account read access to GCS
resource "google_project_iam_binding" "app_engine_storage_viewer" {
  project = google_project.my_project.project_id
  role    = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_project.my_project.project_id}@appspot.gserviceaccount.com",
  ]
  depends_on = [
    google_app_engine_application.app
  ]
}

# Gives the App Engine service account write access to GCS
resource "google_project_iam_binding" "app_engine_storage_creator" {
  project = google_project.my_project.project_id
  role    = "roles/storage.objectCreator"

  members = [
    "serviceAccount:${google_project.my_project.project_id}@appspot.gserviceaccount.com",
  ]
  depends_on = [
    google_app_engine_application.app
  ]
}

# Gives the App Engine service account access to write to Cloud Logging
resource "google_project_iam_binding" "app_engine_log_writer" {
  project = google_project.my_project.project_id
  role    = "roles/logging.logWriter"

  members = [
    "serviceAccount:${google_project.my_project.project_id}@appspot.gserviceaccount.com",
  ]
  depends_on = [
    google_app_engine_application.app
  ]

}

# Gives the App Engine service account access to Firestore
resource "google_project_iam_binding" "app_engine_datastore_user" {
  project = google_project.my_project.project_id
  role    = "roles/datastore.user"

  members = [
    "serviceAccount:${google_project.my_project.project_id}@appspot.gserviceaccount.com",
  ]
  depends_on = [
    google_app_engine_application.app
  ]

}