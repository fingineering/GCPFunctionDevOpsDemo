# first define type of infrastrucutre
terraform {
  required_providers {
    google = {
        source = "hashicorp/google"
        version = "~> 4.3.0"
    }
    google-beta = {
        source = "hashicorp/google-beta"
        version = "~> 4.3.0"
    }
  }
}

######################################################
# define provider configuration
variable "project" {
  type = string
  default = "trusty-dialect-331115"
}
variable "location" {
  type = string
  default = "europe-west3"
}
variable "CODEEDITORUSER" {
  type = string
}

provider "google" {
  project = var.project
  region = var.location
}

provider "google-beta" {
  project = var.project
  region = var.location
}

######################################################
# create service accounts for function and cloud build
resource "google_service_account" "demo_builder" {
  account_id = "cloudbuilderaccount"
}

resource "google_service_account" "demo_function" {
  account_id = "cloudfunctionsaccount"
}

######################################################
# define source repository
resource "google_sourcerepo_repository" "demo_repo" {
  name = "demoFunction"
}

# define the iam binding for the repository
# writing
resource "google_sourcerepo_repository_iam_binding" "demoEditors" {
  project = var.project
  repository = google_sourcerepo_repository.demo_repo.name
  role = "roles/editor"
  members = [
      var.CODEEDITORUSER
  ]
}

# reading
resource "google_sourcerepo_repository_iam_binding" "demoReader" {
  project = var.project
  repository = google_sourcerepo_repository.demo_repo.name
  role = "roles/viewer"
  members = [
      "serviceAccount:${google_service_account.demo_builder.email}",
      "serviceAccount:${google_service_account.demo_function.email}"
  ]
}

######################################################
# create the actual function
resource "google_cloudfunctions_function" "helloWorldDemo" {
    name = "hello_world"
    entry_point = "hello_world"
    description = "A demo function to show how to create a google function"
    runtime = "python39"
    timeout = 300
    trigger_http = true
    source_repository {
        url = "https://source.developers.google.com/projects/${var.project}/repos/${google_sourcerepo_repository.demo_repo.name}/moveable-aliases/main/paths/"
    }
    # service_account_email = google_service_account.hubspot_client.email

    environment_variables = {
        ENVVAR = "FooBar"
    }


}

resource "google_cloudfunctions_function_iam_binding" "demoInvoke" {
    project = google_cloudfunctions_function.helloWorldDemo.project
    region = var.location
    cloud_function = google_cloudfunctions_function.helloWorldDemo.name
    role = "roles/cloudfunctions.invoker"
    members = [
        "${var.CODEEDITORUSER}"
    ]
}

######################################################
# add a build trigger for cloud build 
# 1. add iam binding for build service account
resource "google_cloudfunctions_function_iam_binding" "demoBuilderBinding" {
    project = google_cloudfunctions_function.helloWorldDemo.project
    region = var.location
    cloud_function = google_cloudfunctions_function.helloWorldDemo.name
    role = "roles/cloudfunctions.developer"
    members = [
        "${var.CODEEDITORUSER}",
        "serviceAccount:${google_service_account.demo_builder.email}"
    ]
}

resource "google_project_iam_member" "act_as" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.demo_builder.email}"
}

resource "google_cloudbuild_trigger" "helloTrigger" {
    name = "hellotrigger"
    filename = "cloudbuild.yaml"
    service_account = google_service_account.demo_builder.id
    
    trigger_template {
      branch_name = "main"
      project_id = var.project
      repo_name = google_sourcerepo_repository.demo_repo.name
    }

    depends_on = [
      google_project_iam_member.act_as
    ]
}
