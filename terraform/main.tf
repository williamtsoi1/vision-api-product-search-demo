provider "google" {
  project     = "${var.project_id}-${random_id.project.hex}"
  region      = var.region
}

# Create a random 4 byte suffix on the project id to prevent id collisions
resource "random_id" "project" {
    byte_length = 4
}

resource "google_project" "my_project" {
    name = "Vision API Product Search"
    project_id = "${var.project_id}-${random_id.project.hex}"
    billing_account = var.billing_account_id
}

# Enable APIs
resource "google_project_service" "vision" {
    project = google_project.my_project.project_id
    service = "vision.googleapis.com"
    disable_dependent_services = true
}

resource google_project_service "firestore" {
    project = google_project.my_project.project_id
    service = "firestore.googleapis.com"
    disable_dependent_services = true
}

resource google_project_service "firebase" {
    project = google_project.my_project.project_id
    service = "firebase.googleapis.com"
    disable_dependent_services = true
}
