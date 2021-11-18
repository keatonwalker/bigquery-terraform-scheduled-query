
data "google_project" "project" {
  project_id = "test-project"
}

resource "google_service_account" "scheduled_query_identity" {
  project      = data.google_project.project.project_id
  account_id   = "scheduled-query-identity"
  display_name = "scheduled-query-identity"
  description  = "Service account used to run scheduled queries."
}

resource "google_project_iam_member" "scheduled_query_identity" {
  for_each = toset(["roles/bigquery.dataEditor", "roles/bigquery.jobUser"])
  project  = data.google_project.project.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.scheduled_query_identity.email}"
}

resource "google_bigquery_data_transfer_config" "query_config" {
  depends_on             = [google_project_iam_member.scheduled_query_identity]
  project                = data.google_project.project.project_id
  display_name           = "terraform-scheduled-query"
  location               = "US"
  service_account_name   = google_service_account.scheduled_query_identity.email #must have job user and data editor
  data_source_id         = "scheduled_query"
  schedule               = "every 24 hours"
  destination_dataset_id = "test"
  params = {
    destination_table_name_template = "tftest"
    write_disposition               = "WRITE_APPEND"
    query                           = file("test.sql")
  }
}

