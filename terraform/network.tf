# network - required for App Engine Flex
resource "google_compute_network" "default" {
  project                 = google_project.my_project.project_id
  name                    = "default"
  auto_create_subnetworks = true
}