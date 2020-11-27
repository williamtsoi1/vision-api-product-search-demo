# GCS bucket for images
resource "google_storage_bucket" "images" {
    name = "${google_project.my_project.project_id}_images"
    location = var.region
    force_destroy = true
}

# GCS bucket for bulkload CSV
resource "google_storage_bucket" "bulkload" {
    name = "${google_project.my_project.project_id}_bulkload"
    location = var.region
    force_destroy = true
}