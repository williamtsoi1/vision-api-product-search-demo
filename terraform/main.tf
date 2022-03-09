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

resource google_project_service "runtimeconfig" {
    project = google_project.my_project.project_id
    service = "runtimeconfig.googleapis.com"
    disable_dependent_services = true
}

resource google_project_service "cloudfunctions" {
    project = google_project.my_project.project_id
    service = "cloudfunctions.googleapis.com"
    disable_dependent_services = true
}

resource google_project_service "cloudbuild" {
    project = google_project.my_project.project_id
    service = "cloudbuild.googleapis.com"
    disable_dependent_services = true
}

resource google_project_service "appengineflex" {
    project = google_project.my_project.project_id
    service = "appengineflex.googleapis.com"
    disable_dependent_services = true
}


# Organization policies
resource "google_project_organization_policy" "functions_ingress" {
  project    = google_project.my_project.project_id
  constraint = "cloudfunctions.allowedIngressSettings"

  list_policy {
    allow {
      all = true
    }
  }
}

resource "google_project_organization_policy" "service_account_key_creation" {
  project    = google_project.my_project.project_id
  constraint = "iam.disableServiceAccountKeyCreation"

  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "shielded_vm" {
  project    = google_project.my_project.project_id
  constraint = "compute.requireShieldedVm"

  boolean_policy {
    enforced = false
  }
}

resource "google_project_organization_policy" "vm_external_ip" {
  project    = google_project.my_project.project_id
  constraint = "compute.vmExternalIpAccess"

  list_policy {
    allow {
      all = true
    }
  }
}



resource "google_project_organization_policy" "disable_guest_attribute" {
  project    = google_project.my_project.project_id
  constraint = "compute.disableGuestAttributesAccess"

  boolean_policy {
    enforced = false
  }
}
