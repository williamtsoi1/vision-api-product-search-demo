output "project_id" {
    value = google_project.my_project.project_id
}

output "vision_product_search_service_account_email" {
    value = google_service_account.product_search.email
}

output "vision_product_search_service_account_key" {
    value = google_service_account_key.product_search.private_key
}

output "vision_product_search_buckload_bucket_url" {
    value = google_storage_bucket.bulkload.url
}

output "vision_product_search_images_bucket_url" {
    value = google_storage_bucket.images.url
}
